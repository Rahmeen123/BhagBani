"""Sentinel Hub Statistical API integration."""

from __future__ import annotations

from datetime import date
import math
import os
from typing import Any

import httpx

from app.satellite_analysis.models import (
    AnalysisStatus,
    LandAnalysisRequest,
    LandAnalysisResponse,
    inclusive_time_range,
)


TOKEN_URL = "https://services.sentinel-hub.com/auth/realms/main/protocol/openid-connect/token"
STATISTICS_URL = "https://services.sentinel-hub.com/api/v1/statistics"
CLOUDY_CLASS_THRESHOLD = 60.0
NO_DATA = -9999
EVALSCRIPT = f"""//VERSION=3
function setup() {{
  return {{
    input: [{{ bands: ["B04", "B08", "SCL", "dataMask"] }}],
    output: [
      {{ id: "ndvi", bands: 1, sampleType: "FLOAT32" }},
      {{ id: "vegetation", bands: 1, sampleType: "FLOAT32" }},
      {{ id: "bare", bands: 1, sampleType: "FLOAT32" }},
      {{ id: "cloud", bands: 1, sampleType: "FLOAT32" }},
      {{ id: "dataMask", bands: ["ndvi", "vegetation", "bare", "cloud"] }}
    ]
  }};
}}
function evaluatePixel(sample) {{
  const isObscured = [3, 8, 9, 10].includes(sample.SCL);
  const denominator = sample.B08 + sample.B04;
  const ndvi = denominator === 0 ? 0 : (sample.B08 - sample.B04) / denominator;
  const validLandPixel = sample.dataMask *
    (isObscured || sample.SCL === 6 || sample.SCL === 11 || denominator === 0 ? 0 : 1);
  return {{
    ndvi: [ndvi],
    vegetation: [ndvi >= 0.3 ? 1 : 0],
    bare: [ndvi < 0.2 ? 1 : 0],
    cloud: [isObscured ? 1 : 0],
    dataMask: [validLandPixel, validLandPixel, validLandPixel, sample.dataMask]
  }};
}}"""


class SentinelHubConfigurationError(RuntimeError):
    """Raised when Sentinel Hub credentials are not configured."""


class SentinelHubServiceError(RuntimeError):
    """Raised when the Sentinel Hub request fails or returns invalid data."""


class SentinelHubStatisticalService:
    def __init__(self, client: httpx.AsyncClient | None = None) -> None:
        self.client = client

    async def analyze(self, request: LandAnalysisRequest) -> LandAnalysisResponse:
        client = self.client
        if client is None:
            async with httpx.AsyncClient(timeout=45) as owned_client:
                return await self._analyze(request, owned_client)
        return await self._analyze(request, client)

    async def _analyze(
        self, request: LandAnalysisRequest, client: httpx.AsyncClient
    ) -> LandAnalysisResponse:
        client_id = os.getenv("SENTINEL_HUB_CLIENT_ID")
        client_secret = os.getenv("SENTINEL_HUB_CLIENT_SECRET")
        if not client_id or not client_secret:
            raise SentinelHubConfigurationError("Sentinel Hub credentials are not configured.")

        try:
            token_response = await client.post(
                TOKEN_URL,
                data={
                    "grant_type": "client_credentials",
                    "client_id": client_id,
                    "client_secret": client_secret,
                },
            )
            token_response.raise_for_status()
            access_token = token_response.json()["access_token"]
            payload = self._statistics_payload(request)
            response = await client.post(
                STATISTICS_URL,
                json=payload,
                headers={"Authorization": f"Bearer {access_token}"},
            )
            response.raise_for_status()
            statistics = response.json()
            if not isinstance(statistics, dict):
                raise SentinelHubServiceError("Sentinel Hub returned invalid statistics.")
            return self._parse_statistics(statistics)
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            raise SentinelHubServiceError("Sentinel Hub analysis request failed.") from exc

    @staticmethod
    def _statistics_payload(request: LandAnalysisRequest) -> dict[str, Any]:
        time_range = inclusive_time_range(request.start_date, request.end_date)
        return {
            "input": {
                "bounds": {
                    "geometry": request.geometry,
                    "properties": {"crs": "http://www.opengis.net/def/crs/EPSG/0/4326"},
                },
                "data": [
                    {
                        "type": "sentinel-2-l2a",
                        "dataFilter": {
                            "maxCloudCoverage": 100,
                        },
                    }
                ],
            },
            "aggregation": {
                "timeRange": time_range,
                "aggregationInterval": {"of": "P1D"},
                "resx": 10,
                "resy": 10,
                "evalscript": EVALSCRIPT,
            },
        }

    @staticmethod
    def _parse_statistics(payload: dict[str, Any]) -> LandAnalysisResponse:
        data = payload.get("data")
        if not isinstance(data, list) or not data:
            return LandAnalysisResponse.inconclusive()

        candidates: list[tuple[float, date, dict[str, float | None]]] = []
        for item in data:
            if not isinstance(item, dict):
                continue
            interval = item.get("interval", {})
            outputs = item.get("outputs", {})
            if not isinstance(interval, dict) or not isinstance(outputs, dict):
                continue
            try:
                observation_date = date.fromisoformat(str(interval["from"])[:10])
            except (KeyError, ValueError):
                continue
            means: dict[str, float | None] = {}
            for output_id in ("ndvi", "vegetation", "bare", "cloud"):
                output = outputs.get(output_id, {})
                bands = output.get("bands", {}) if isinstance(output, dict) else {}
                band = bands.get("B0", {}) if isinstance(bands, dict) else {}
                stats = band.get("stats", {}) if isinstance(band, dict) else {}
                mean = stats.get("mean") if isinstance(stats, dict) else None
                if (
                    isinstance(mean, (int, float))
                    and not isinstance(mean, bool)
                    and math.isfinite(mean)
                    and mean != NO_DATA
                ):
                    means[output_id] = float(mean)
                else:
                    means[output_id] = None
            cloud_fraction = means["cloud"]
            if cloud_fraction is not None:
                candidates.append((cloud_fraction, observation_date, means))

        if not candidates:
            return LandAnalysisResponse.inconclusive()
        conclusive_candidates = [
            candidate
            for candidate in candidates
            if candidate[0] * 100 < CLOUDY_CLASS_THRESHOLD
            and all(candidate[2][metric] is not None for metric in ("ndvi", "vegetation", "bare"))
        ]
        cloud_fraction, observation_date, best = min(
            conclusive_candidates or candidates,
            key=lambda candidate: (candidate[0], -candidate[1].toordinal()),
        )
        cloud_percentage = min(100.0, max(0.0, cloud_fraction * 100))
        vegetation_percentage = (
            min(100.0, max(0.0, best["vegetation"] * 100))
            if best["vegetation"] is not None
            else None
        )
        bare_land_percentage = (
            min(100.0, max(0.0, best["bare"] * 100))
            if best["bare"] is not None
            else None
        )
        status = (
            AnalysisStatus.INCONCLUSIVE
            if cloud_percentage >= CLOUDY_CLASS_THRESHOLD or best["ndvi"] is None
            else AnalysisStatus.CONCLUSIVE
        )
        return LandAnalysisResponse(
            vegetation_percentage=vegetation_percentage,
            bare_land_percentage=bare_land_percentage,
            cloud_percentage=cloud_percentage,
            average_ndvi=(
                min(1.0, max(-1.0, best["ndvi"]))
                if best["ndvi"] is not None
                else None
            ),
            analysis_status=status,
            observation_date=observation_date,
        )

