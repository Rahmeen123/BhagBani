from __future__ import annotations

import asyncio
from datetime import date, timedelta
import json
import os
import unittest
from unittest.mock import AsyncMock, patch

import httpx
from pydantic import ValidationError

from app import main
from app.satellite_analysis.models import (
    AnalysisStatus,
    LandAnalysisRequest,
    LandAnalysisResponse,
)
from app.satellite_analysis.service import (
    SentinelHubServiceError,
    SentinelHubStatisticalService,
)


def valid_request() -> LandAnalysisRequest:
    today = date.today()
    return LandAnalysisRequest(
        geometry={
            "type": "Polygon",
            "coordinates": [[
                [74.35, 31.52],
                [74.351, 31.52],
                [74.351, 31.521],
                [74.35, 31.521],
                [74.35, 31.52],
            ]],
        },
        start_date=today - timedelta(days=14),
        end_date=today - timedelta(days=1),
    )


class SatelliteRequestValidationTests(unittest.TestCase):
    def test_rejects_non_polygon_geometry(self) -> None:
        body = valid_request().model_dump()
        body["geometry"] = {"type": "Point", "coordinates": [74.35, 31.52]}
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

    def test_rejects_unclosed_polygon(self) -> None:
        body = valid_request().model_dump()
        body["geometry"]["coordinates"][0][-1] = [74.35, 31.521]
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

    def test_rejects_polygons_outside_area_limits(self) -> None:
        body = valid_request().model_dump()
        body["geometry"]["coordinates"] = [[
            [74.35, 31.52],
            [75.35, 31.52],
            [75.35, 32.52],
            [74.35, 32.52],
            [74.35, 31.52],
        ]]
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

        body = valid_request().model_dump()
        body["geometry"]["coordinates"] = [[
            [74.35, 31.52],
            [74.350001, 31.52],
            [74.350001, 31.520001],
            [74.35, 31.520001],
            [74.35, 31.52],
        ]]
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

    def test_rejects_self_intersecting_polygon(self) -> None:
        body = valid_request().model_dump()
        body["geometry"]["coordinates"] = [[
            [74.35, 31.52],
            [74.351, 31.521],
            [74.351, 31.52],
            [74.35, 31.521],
            [74.35, 31.52],
        ]]
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

    def test_rejects_invalid_date_ranges(self) -> None:
        body = valid_request().model_dump()
        body["start_date"] = date.today()
        body["end_date"] = date.today() - timedelta(days=1)
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)

        body = valid_request().model_dump()
        body["start_date"] = date.today() - timedelta(days=500)
        with self.assertRaises(ValidationError):
            LandAnalysisRequest(**body)


class SentinelStatisticsTests(unittest.TestCase):
    def test_selects_clear_observation_and_computes_ndvi_metrics(self) -> None:
        response = SentinelHubStatisticalService._parse_statistics(
            {
                "data": [
                    self._day("2026-11-20", ndvi=0.4, vegetation=0.7, bare=0.2, cloud=0.1),
                    self._day("2026-11-21", ndvi=0.2, vegetation=0.3, bare=0.4, cloud=0.8),
                ]
            }
        )

        self.assertEqual(response.analysis_status, AnalysisStatus.CONCLUSIVE)
        self.assertEqual(response.observation_date, date(2026, 11, 20))
        self.assertEqual(response.vegetation_percentage, 70)
        self.assertEqual(response.bare_land_percentage, 20)
        self.assertEqual(response.cloud_percentage, 10)
        self.assertEqual(response.average_ndvi, 0.4)

    def test_empty_or_cloudy_satellite_result_is_inconclusive(self) -> None:
        no_data = SentinelHubStatisticalService._parse_statistics({"data": []})
        cloudy = SentinelHubStatisticalService._parse_statistics(
            {
                "data": [
                    {
                        "interval": {"from": "2026-11-20T00:00:00Z"},
                        "outputs": {
                            "cloud": {
                                "bands": {"B0": {"stats": {"mean": 0.9}}}
                            }
                        },
                    }
                ]
            }
        )

        self.assertEqual(no_data.analysis_status, AnalysisStatus.INCONCLUSIVE)
        self.assertIsNone(no_data.average_ndvi)
        self.assertEqual(cloudy.analysis_status, AnalysisStatus.INCONCLUSIVE)
        self.assertEqual(cloudy.cloud_percentage, 90)
        self.assertIsNone(cloudy.vegetation_percentage)

    def test_statistical_request_uses_sentinel_2_l2a_and_inclusive_dates(self) -> None:
        request = valid_request()

        payload = SentinelHubStatisticalService._statistics_payload(request)

        self.assertEqual(payload["input"]["data"][0]["type"], "sentinel-2-l2a")
        self.assertEqual(
            payload["aggregation"]["timeRange"]["to"],
            f"{(request.end_date + timedelta(days=1)).isoformat()}T00:00:00Z",
        )

    def test_service_authenticates_then_requests_statistics(self) -> None:
        request = valid_request()

        async def handler(http_request: httpx.Request) -> httpx.Response:
            if http_request.url.path.endswith("/protocol/openid-connect/token"):
                form = http_request.content.decode()
                self.assertIn("client_id=test-client", form)
                self.assertIn("client_secret=test-secret", form)
                return httpx.Response(200, json={"access_token": "test-token"})

            self.assertEqual(
                http_request.headers.get("Authorization"), "Bearer test-token"
            )
            payload = json.loads(http_request.content)
            self.assertEqual(
                payload["input"]["data"][0]["type"], "sentinel-2-l2a"
            )
            return httpx.Response(
                200,
                json={
                    "data": [
                        SentinelStatisticsTests._day(
                            request.start_date.isoformat(), 0.45, 0.7, 0.2, 0.1
                        )
                    ]
                },
            )

        async def analyze() -> LandAnalysisResponse:
            async with httpx.AsyncClient(
                transport=httpx.MockTransport(handler)
            ) as client:
                return await SentinelHubStatisticalService(client).analyze(request)

        with patch.dict(
            os.environ,
            {
                "SENTINEL_HUB_CLIENT_ID": "test-client",
                "SENTINEL_HUB_CLIENT_SECRET": "test-secret",
            },
        ):
            result = asyncio.run(analyze())

        self.assertEqual(result.analysis_status, AnalysisStatus.CONCLUSIVE)
        self.assertEqual(result.average_ndvi, 0.45)

    @staticmethod
    def _day(
        observation_date: str,
        ndvi: float,
        vegetation: float,
        bare: float,
        cloud: float,
    ) -> dict:
        return {
            "interval": {"from": f"{observation_date}T00:00:00Z"},
            "outputs": {
                output_id: {"bands": {"B0": {"stats": {"mean": value}}}}
                for output_id, value in {
                    "ndvi": ndvi,
                    "vegetation": vegetation,
                    "bare": bare,
                    "cloud": cloud,
                }.items()
            },
        }


class SatelliteApiTests(unittest.TestCase):
    def test_analysis_service_failure_returns_inconclusive_contract(self) -> None:
        async def make_request() -> httpx.Response:
            with (
                patch.object(main.CropRecommender, "load", return_value=object()),
                patch(
                    "app.satellite_analysis.router.SentinelHubStatisticalService.analyze",
                    new=AsyncMock(
                        side_effect=SentinelHubServiceError("provider unavailable")
                    ),
                ),
                patch(
                    "app.satellite_analysis.router.logger.exception"
                ) as log_exception,
            ):
                async with main.lifespan(main.app):
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        response = await client.post(
                            "/analyze-land",
                            json=valid_request().model_dump(mode="json"),
                        )
                log_exception.assert_called_once()
                return response

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                "vegetation_percentage": None,
                "bare_land_percentage": None,
                "cloud_percentage": None,
                "average_ndvi": None,
                "analysis_status": "inconclusive",
                "observation_date": None,
            },
        )

    def test_invalid_polygon_returns_422(self) -> None:
        async def make_request() -> httpx.Response:
            with patch.object(main.CropRecommender, "load", return_value=object()):
                async with main.lifespan(main.app):
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        return await client.post(
                            "/analyze-land",
                            json={
                                "geometry": {
                                    "type": "Point",
                                    "coordinates": [74.35, 31.52],
                                },
                                "start_date": "2026-11-01",
                                "end_date": "2026-11-20",
                            },
                        )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 422)


if __name__ == "__main__":
    unittest.main()
