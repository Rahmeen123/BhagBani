from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from datetime import date
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import AsyncMock, patch

import httpx
import pandas as pd

from app import main
from app.prediction import CropRecommender
from app.weather import (
    WeatherServiceError,
    WeatherSnapshot,
    fetch_daily_weather,
    fetch_weather,
)
from model.train_model import (
    BASE_FEATURE_COLUMNS,
    FEATURE_COLUMNS,
    WEATHER_CACHE_SCHEMA_VERSION,
    _power_cell,
    _stratified_holdout_indices,
    add_historical_weather,
    build_description_mapping,
    build_pipeline,
    prepare_dataset,
)


@asynccontextmanager
async def test_lifespan():
    with (
        patch.object(
            main.PlantRecommendationService, "load", return_value=object()
        ),
        patch.object(main.PlantHealthAnalyzer, "load", return_value=object()),
    ):
        async with main.lifespan(main.app):
            yield


class DatasetPreparationTests(unittest.TestCase):
    def test_stratified_holdout_keeps_each_class_in_both_splits(self) -> None:
        labels = pd.Series(
            ["Rice", "Rice", "Rice", "Wheat", "Wheat", "Maize", "Maize"],
            index=[10, 11, 12, 20, 21, 30, 31],
        )

        training_indices, holdout_indices = _stratified_holdout_indices(labels)

        self.assertEqual(
            set(training_indices) | set(holdout_indices), set(labels.index)
        )
        self.assertFalse(set(training_indices) & set(holdout_indices))
        for crop in labels.unique():
            crop_indices = set(labels[labels == crop].index)
            self.assertTrue(crop_indices & set(training_indices))
            self.assertTrue(crop_indices & set(holdout_indices))

    def test_keeps_only_major_crops_at_minimum_count(self) -> None:
        def record(description: str, observation_date: object, index: int) -> dict:
            return {
                "ID": f"record-{index}",
                "Season": "Kharif",
                "Province": "Punjab",
                "District": "Lahore",
                "Date": observation_date,
                "Latitude": 31.52,
                "Longitude": 74.35,
                "Code": index,
                "Land": "Cropland",
                "Description": description,
                "Stage": "",
            }

        rows = pd.DataFrame(
            [
                *[
                    record("Maize (Corn)", "20/08/2023", index)
                    for index in range(50)
                ],
                *[
                    record("Rice", 45116, index)
                    for index in range(50, 100)
                ],
                *[
                    record("Chickpea", "20/08/2023", index)
                    for index in range(100, 149)
                ],
                *[
                    record("MANGO", "20/08/2023", index)
                    for index in range(149, 199)
                ],
                record("Rice and Wheat", "20/08/2023", 199),
                record("Water", "20/08/2023", 200),
            ]
        )
        with tempfile.TemporaryDirectory() as temporary_directory:
            source_path = Path(temporary_directory) / "ground_truth.xlsx"
            rows.to_excel(source_path, index=False)
            processed = prepare_dataset(source_path)

        self.assertEqual(len(processed), 100)
        self.assertEqual(
            processed["Crop"].value_counts().to_dict(),
            {"Maize": 50, "Rice": 50},
        )
        self.assertEqual(processed.loc[0, "Month"], 8)
        self.assertEqual(processed.loc[50, "Month"], 7)
        self.assertEqual(
            list(processed.columns),
            ["Date", *BASE_FEATURE_COLUMNS, "Crop"],
        )

    def test_standardizes_major_crop_aliases_and_filters_rare_classes(self) -> None:
        def rows_for(description: str, count: int, land: str = "Cropland"):
            return [
                [
                    "Kharif",
                    "Punjab",
                    "Lahore",
                    "20/08/2023",
                    31.52,
                    74.35,
                    land,
                    description,
                ]
                for _ in range(count)
            ]

        rows = (
            rows_for("Maize (Corn)", 25)
            + rows_for("Maize", 25)
            + rows_for("Ground nuts/Peanuts", 50)
            + rows_for("Sesame (Til)", 50)
            + rows_for("Chickpea", 49)
            + rows_for("MANGO", 50, "Orchard")
        )
        rows = pd.DataFrame(
            rows,
            columns=[
                "Season",
                "Province",
                "District",
                "Date",
                "Latitude",
                "Longitude",
                "Land",
                "Description",
            ],
        )
        with tempfile.TemporaryDirectory() as temporary_directory:
            source_path = Path(temporary_directory) / "ground_truth.xlsx"
            rows.to_excel(source_path, index=False)
            processed = prepare_dataset(source_path)

        self.assertEqual(
            processed["Crop"].value_counts().to_dict(),
            {"Maize": 50, "Groundnut": 50, "Sesame": 50},
        )

    def test_mapping_records_crop_mixed_and_non_crop_dispositions(self) -> None:
        mapping = build_description_mapping(
            ["Maize (Corn)", "Rice and Wheat", "Builtup", "BAMBOO"]
        ).set_index("Source_Description")

        self.assertEqual(
            mapping.loc["Maize (Corn)", "Standardized_Description"],
            "Maize",
        )
        self.assertEqual(mapping.loc["Maize (Corn)", "Class_Type"], "crop")
        self.assertEqual(
            mapping.loc["Rice and Wheat", "Class_Type"], "mixed_crop"
        )
        self.assertFalse(mapping.loc["Rice and Wheat", "Included_In_Training"])
        self.assertEqual(mapping.loc["Builtup", "Class_Type"], "non_crop")
        self.assertFalse(mapping.loc["Builtup", "Included_In_Training"])
        self.assertEqual(
            mapping.loc["BAMBOO", "Standardized_Description"], "Bamboo"
        )
        self.assertFalse(mapping.loc["BAMBOO", "Included_In_Training"])

    def test_weather_values_join_by_location_cell_and_observation_date(self) -> None:
        records = pd.DataFrame(
            [
                ["2023-08-20", 31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, "Rice"],
                ["2023-08-21", 31.53, 74.36, "Punjab", "Lahore", "Kharif", 8, "Rice"],
            ],
            columns=["Date", *BASE_FEATURE_COLUMNS, "Crop"],
        )
        key, cell_latitude, cell_longitude = _power_cell(31.52, 74.35)
        observations = {
            "20230820": {
                "T2M": 30.0,
                "PRECTOTCORR": 2.0,
                "RH2M": 60.0,
            },
            "20230821": {
                "T2M": 31.0,
                "PRECTOTCORR": 3.0,
                "RH2M": None,
            },
        }
        with tempfile.TemporaryDirectory() as temporary_directory:
            cache_dir = Path(temporary_directory)
            (cache_dir / f"{key}.json").write_text(
                json.dumps(
                    {
                        "schema_version": WEATHER_CACHE_SCHEMA_VERSION,
                        "latitude": cell_latitude,
                        "longitude": cell_longitude,
                        "start_date": "2023-08-20",
                        "end_date": "2023-08-21",
                        "observations": observations,
                    }
                ),
                encoding="utf-8",
            )
            enriched = add_historical_weather(records, cache_dir)

        self.assertEqual(enriched["Temperature"].tolist(), [30.0, 31.0])
        self.assertEqual(enriched["Rainfall"].tolist(), [2.0, 3.0])
        self.assertEqual(enriched.loc[0, "Humidity"], 60.0)
        self.assertTrue(pd.isna(enriched.loc[1, "Humidity"]))


class PredictionTests(unittest.TestCase):
    def test_recommendation_uses_weather_features(self) -> None:
        rows = pd.DataFrame(
            [
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 30, 8, 70, "Rice"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 30, 9, 70, "Rice"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 29, 8, 68, "Rice"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 31, 9, 72, "Rice"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 18, 1, 40, "Wheat"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 19, 1, 42, "Wheat"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 18, 2, 41, "Wheat"],
                [31.52, 74.35, "Punjab", "Lahore", "Kharif", 8, 20, 1, 39, "Wheat"],
            ],
            columns=[*FEATURE_COLUMNS, "Crop"],
        )
        model = build_pipeline()
        model.set_params(
            classifier__max_samples=None,
            classifier__min_samples_leaf=1,
            classifier__class_weight=None,
        )
        model.fit(rows[FEATURE_COLUMNS], rows["Crop"])
        recommender = CropRecommender(model, rows[BASE_FEATURE_COLUMNS])

        warm_result = recommender.recommend(
            31.52, 74.35, month=8, temperature=30, rainfall=8, humidity=70
        )
        cold_result = recommender.recommend(
            31.52, 74.35, month=8, temperature=18, rainfall=1, humidity=40
        )

        self.assertEqual(warm_result.location, "Lahore, Punjab")
        self.assertEqual(warm_result.season, "Kharif")
        self.assertEqual(warm_result.recommendations[0].crop, "Rice")
        self.assertEqual(cold_result.recommendations[0].crop, "Wheat")
        self.assertTrue(
            all(
                0 <= item.confidence <= 100
                for item in warm_result.recommendations
            )
        )


class WeatherAggregationTests(unittest.TestCase):
    def test_historical_api_values_are_mapped_by_day(self) -> None:
        payload = {
            "properties": {
                "parameter": {
                    "T2M": {"20230820": 30, "20230821": -999},
                    "PRECTOTCORR": {"20230820": 2, "20230821": 0},
                    "RH2M": {"20230820": 60},
                }
            }
        }

        async def handler(_: httpx.Request) -> httpx.Response:
            return httpx.Response(200, json=payload)

        async def fetch() -> dict[str, dict[str, float | None]]:
            async with httpx.AsyncClient(
                transport=httpx.MockTransport(handler)
            ) as client:
                return await fetch_daily_weather(
                    31.5,
                    74.375,
                    date(2023, 8, 20),
                    date(2023, 8, 21),
                    client,
                )

        daily = asyncio.run(fetch())

        self.assertEqual(daily["20230820"]["T2M"], 30)
        self.assertEqual(daily["20230821"]["T2M"], None)
        self.assertEqual(daily["20230821"]["PRECTOTCORR"], 0)
        self.assertEqual(daily["20230820"]["RH2M"], 60)

    def test_recent_weather_returns_latest_usable_day(self) -> None:
        async def handler(request: httpx.Request) -> httpx.Response:
            day = request.url.params["end"]
            return httpx.Response(
                200,
                json={
                    "properties": {
                        "parameter": {
                            "T2M": {day: 29.5},
                            "PRECTOTCORR": {day: 1.2},
                            "RH2M": {day: 58},
                        }
                    }
                },
            )

        async def fetch() -> WeatherSnapshot:
            async with httpx.AsyncClient(
                transport=httpx.MockTransport(handler)
            ) as client:
                return await fetch_weather(31.52, 74.35, 8, client=client)

        weather = asyncio.run(fetch())

        self.assertEqual(weather.temperature_c, 29.5)
        self.assertEqual(weather.rainfall_mm, 1.2)
        self.assertEqual(weather.humidity_percent, 58)
        self.assertEqual(weather.days_averaged, 1)


class ApiTests(unittest.TestCase):
    def test_recommendation_endpoint_returns_weather_and_top_crops(self) -> None:
        weather = WeatherSnapshot(
            temperature_c=30,
            rainfall_mm=0.96,
            humidity_percent=55,
            month=11,
            period_start="2026-11-24",
            period_end="2026-11-24",
            days_averaged=1,
        )

        async def make_request() -> httpx.Response:
            with patch.object(
                main, "fetch_weather", new=AsyncMock(return_value=weather)
            ):
                async with test_lifespan():
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        return await client.post(
                            "/recommend-crop",
                            json={"latitude": 31.5204, "longitude": 74.3587},
                        )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(
            set(body), {"location", "weather", "recommendations"}
        )
        self.assertEqual(
            set(body["weather"]), {"temperature", "rainfall", "humidity"}
        )
        self.assertEqual(body["weather"]["temperature"], 30)
        self.assertEqual(len(body["recommendations"]), 3)
        self.assertEqual(
            set(body["recommendations"][0]),
            {"crop_name", "confidence_percentage"},
        )

    def test_invalid_coordinates_and_extra_fields_return_422(self) -> None:
        async def make_requests() -> tuple[httpx.Response, httpx.Response]:
            with patch.object(
                main.CropRecommender, "load", return_value=object()
            ):
                async with test_lifespan():
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        invalid_coordinate = await client.post(
                            "/recommend-crop",
                            json={"latitude": 91, "longitude": 74},
                        )
                        extra_field = await client.post(
                            "/recommend-crop",
                            json={
                                "latitude": 31,
                                "longitude": 74,
                                "city": "Lahore",
                            },
                        )
                        return invalid_coordinate, extra_field

        invalid_coordinate, extra_field = asyncio.run(make_requests())

        self.assertEqual(invalid_coordinate.status_code, 422)
        self.assertEqual(extra_field.status_code, 422)

    def test_nasa_weather_failure_returns_502(self) -> None:
        async def make_request() -> httpx.Response:
            with (
                patch.object(
                    main.CropRecommender, "load", return_value=object()
                ),
                patch.object(
                    main,
                    "fetch_weather",
                    new=AsyncMock(
                        side_effect=WeatherServiceError("NASA unavailable")
                    ),
                ),
            ):
                async with test_lifespan():
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        return await client.post(
                            "/recommend-crop",
                            json={"latitude": 31, "longitude": 74},
                        )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 502)
        self.assertEqual(response.json()["detail"], "NASA unavailable")

    def test_prediction_failure_returns_sanitized_500(self) -> None:
        class FailingRecommender:
            def recommend(self, **_: object) -> None:
                raise RuntimeError("private model failure")

        weather = WeatherSnapshot(
            temperature_c=30,
            rainfall_mm=1,
            humidity_percent=55,
            month=11,
            period_start="2026-11-24",
            period_end="2026-11-24",
            days_averaged=1,
        )

        async def make_request() -> httpx.Response:
            with (
                patch.object(
                    main.CropRecommender,
                    "load",
                    return_value=FailingRecommender(),
                ),
                patch.object(
                    main, "fetch_weather", new=AsyncMock(return_value=weather)
                ),
            ):
                async with test_lifespan():
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        return await client.post(
                            "/recommend-crop",
                            json={"latitude": 31, "longitude": 74},
                        )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 500)
        self.assertEqual(
            response.json()["detail"],
            "The crop recommendation could not be generated.",
        )


if __name__ == "__main__":
    unittest.main()
