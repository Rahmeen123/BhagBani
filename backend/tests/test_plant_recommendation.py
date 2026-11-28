from __future__ import annotations

import asyncio
import csv
import unittest
from pathlib import Path
from unittest.mock import patch

import httpx

from app import main
from app.plant_health import (
    DISCLAIMER,
    LOW_CONFIDENCE_MESSAGE,
    PHOTO_MISMATCH_MESSAGE,
    PlantHealthAnalyzer,
    PlantHealthResponse,
)
from app.plant_recommendation import (
    PlantRecord,
    PlantRecommendationRequest,
    PlantRecommendationService,
)
from clean_dataset import OUTPUT_COLUMNS, clean_rows


def plant(
    name: str,
    *,
    care_level: str = "Regular",
    soil: str = "loamy",
    growth: str = "moderate",
    sunlight: str = "full sunlight",
) -> PlantRecord:
    return PlantRecord(
        name=name,
        growth=growth,
        soil=soil,
        sunlight=sunlight,
        care_level=care_level,  # type: ignore[arg-type]
        watering_text="Water weekly",
        fertilization="Organic",
        health_supported=False,
        health_label_prefix="",
    )


class CleanDatasetTests(unittest.TestCase):
    def test_cp1252_source_is_deduplicated_and_has_required_health_metadata(self):
        source = (
            Path(__file__).resolve().parents[2]
            / "dataset for plant recommendation"
            / "plants.csv"
        )
        with source.open(encoding="cp1252", newline="") as csv_file:
            rows = list(csv.DictReader(csv_file))

        cleaned = clean_rows(rows)

        self.assertEqual(len(rows), 596)
        self.assertEqual(len(cleaned), 387)
        self.assertEqual(tuple(cleaned[0]), OUTPUT_COLUMNS)
        self.assertEqual(len({row["name"].casefold() for row in cleaned}), 387)

        plants_by_name = {
            row["name"].casefold(): row for row in cleaned
        }
        expected_prefixes = {
            "tomato": "Tomato___",
            "apple tree": "Apple___",
            "corn": "Corn_(maize)___",
            "grape vine": "Grape___",
            "strawberry": "Strawberry___",
            "strawberry plant": "Strawberry___",
            "pepper plant": "Pepper,_bell___",
            "acorn squash": "Squash___",
            "butternut squash": "Squash___",
            "raspberry": "Raspberry___",
        }
        for name, prefix in expected_prefixes.items():
            self.assertEqual(
                plants_by_name[name]["health_supported"], "true", name
            )
            self.assertEqual(
                plants_by_name[name]["health_label_prefix"], prefix, name
            )

        for unsupported in (
            "chili pepper",
            "cherry blossom",
            "potato vine",
            "sweet potato vine",
            "mayapple",
            "pineapple",
            "cornflower",
            "grape hyacinth",
        ):
            self.assertEqual(
                plants_by_name[unsupported]["health_supported"], "false"
            )


class ExactFilterTests(unittest.TestCase):
    def test_exact_filters_then_growth_soil_and_adjacent_care_fallbacks(self):
        service = PlantRecommendationService(
            [
                plant("Exact", soil="sandy", growth="fast"),
                plant("No Growth Match", soil="sandy", growth="slow"),
                plant("No Soil Match", soil="loamy", growth="moderate"),
            ]
        )

        growth_fallback = service.recommend(
            PlantRecommendationRequest(
                sunlight="Full Sun",
                care_level="Regular",
                soil="sandy",
                growth="Moderate",
            )
        )
        self.assertEqual(
            [record.name for record in growth_fallback],
            ["Exact", "No Growth Match"],
        )

        soil_fallback = PlantRecommendationService(
            [plant("Loamy", soil="loamy", growth="slow")]
        ).recommend(
            PlantRecommendationRequest(
                sunlight="Full Sun",
                care_level="Regular",
                soil="sandy",
                growth="Fast",
            )
        )
        self.assertEqual([record.name for record in soil_fallback], ["Loamy"])

        adjacent_fallback = PlantRecommendationService(
            [
                plant("Regular Care", care_level="Regular"),
                plant("High Care", care_level="High"),
                plant("Wrong Sun", care_level="Regular", sunlight="partial sunlight"),
            ]
        ).recommend(
            PlantRecommendationRequest(
                sunlight="Full Sun",
                care_level="Low",
                soil="acidic",
                growth="Fast",
            )
        )
        self.assertEqual(
            [record.name for record in adjacent_fallback],
            ["Regular Care"],
        )

    def test_no_matching_sunlight_returns_no_recommendations(self):
        result = PlantRecommendationService(
            [plant("Shade Plant", sunlight="indirect sunlight")]
        ).recommend(
            PlantRecommendationRequest(
                sunlight="Full Sun",
                care_level="Regular",
            )
        )
        self.assertEqual(result, [])


class PlantHealthInterpretationTests(unittest.TestCase):
    LABELS = {
        0: "Tomato___healthy",
        1: "Tomato___Late_blight",
        2: "Apple___Apple_scab",
        3: "Corn_(maize)___Common_rust_",
    }

    def test_returns_dynamic_healthy_and_disease_labels(self):
        healthy = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels=self.LABELS,
            probabilities=[0.8, 0.1, 0.05, 0.05],
        )
        disease = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels=self.LABELS,
            probabilities=[0.1, 0.8, 0.05, 0.05],
        )

        self.assertEqual(healthy.status, "healthy")
        self.assertEqual(healthy.label, "Healthy")
        self.assertEqual(healthy.disclaimer, DISCLAIMER)
        self.assertEqual(disease.status, "disease")
        self.assertEqual(disease.label, "Late Blight")
        self.assertTrue(disease.treatment_tips)

    def test_other_species_and_low_confidence_require_a_retake(self):
        other_species = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels=self.LABELS,
            probabilities=[0.1, 0.05, 0.8, 0.05],
        )
        uncertain_other_species = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels=self.LABELS,
            probabilities=[0.134, 0.1, 0.482, 0.284],
        )
        low_confidence = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels=self.LABELS,
            probabilities=[0.59, 0.2, 0.15, 0.06],
        )

        self.assertEqual(other_species.message, PHOTO_MISMATCH_MESSAGE)
        self.assertEqual(other_species.disclaimer, DISCLAIMER)
        self.assertEqual(
            uncertain_other_species.message, LOW_CONFIDENCE_MESSAGE
        )
        self.assertEqual(uncertain_other_species.confidence, 0.482)
        self.assertEqual(low_confidence.message, LOW_CONFIDENCE_MESSAGE)
        self.assertEqual(low_confidence.confidence, 0.59)

    def test_hugging_face_labels_keep_the_raw_top_tomato_disease(self):
        result = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels={
                0: "Tomato with Bacterial Spot",
                1: "Tomato Mosaic Virus",
            },
            probabilities=[0.8, 0.2],
        )

        self.assertEqual(result.status, "disease")
        self.assertEqual(result.label, "Tomato With Bacterial Spot")
        self.assertEqual(result.confidence, 0.8)

    def test_hugging_face_healthy_plant_label_is_not_reported_as_disease(self):
        result = PlantHealthAnalyzer.interpret_predictions(
            plant_name="Tomato",
            labels={
                0: "Healthy Tomato Plant",
                1: "Tomato Mosaic Virus",
            },
            probabilities=[0.99, 0.01],
        )

        self.assertEqual(result.status, "healthy")
        self.assertEqual(result.label, "Healthy")

    def test_unsupported_plant_does_not_get_a_health_prediction(self):
        with self.assertRaisesRegex(ValueError, "not supported"):
            PlantHealthAnalyzer.interpret_predictions(
                plant_name="Chili Pepper",
                labels=self.LABELS,
                probabilities=[0.8, 0.1, 0.05, 0.05],
            )


class PlantApiTests(unittest.TestCase):
    def test_recommendation_and_health_endpoints_return_expected_contracts(self):
        class FakeAnalyzer:
            def analyze(self, image_bytes: bytes, plant_name: str):
                return PlantHealthResponse(
                    status="healthy",
                    label="Healthy",
                    confidence=0.92,
                    treatment_tips=["Continue routine care."],
                )

        service = PlantRecommendationService(
            [
                plant("Tomato", care_level="Regular", growth="fast"),
                plant("Low Care Tomato", care_level="Low"),
            ]
        )

        async def make_requests():
            with (
                patch.object(
                    main.CropRecommender, "load", return_value=object()
                ),
                patch.object(
                    main.PlantRecommendationService,
                    "load",
                    return_value=service,
                ),
                patch.object(
                    main.PlantHealthAnalyzer,
                    "load",
                    return_value=FakeAnalyzer(),
                ),
            ):
                async with main.lifespan(main.app):
                    async with httpx.AsyncClient(
                        transport=httpx.ASGITransport(app=main.app),
                        base_url="http://test",
                    ) as client:
                        recommendation = await client.post(
                            "/recommend",
                            json={
                                "sunlight": "Full Sun",
                                "care_level": "Regular",
                                "growth": "Fast",
                            },
                        )
                        health = await client.post(
                            "/health-analysis",
                            data={"plant_name": "Tomato"},
                            files={
                                "image": (
                                    "leaf.jpg",
                                    b"test image",
                                    "image/jpeg",
                                )
                            },
                        )
                        unsupported = await client.post(
                            "/health-analysis",
                            data={"plant_name": "Chili Pepper"},
                            files={
                                "image": (
                                    "leaf.jpg",
                                    b"test image",
                                    "image/jpeg",
                                )
                            },
                        )
                        return recommendation, health, unsupported

        recommendation, health, unsupported = asyncio.run(make_requests())

        self.assertEqual(recommendation.status_code, 200)
        record = recommendation.json()["recommendations"][0]
        self.assertEqual(
            set(record),
            {
                "name",
                "growth",
                "soil",
                "sunlight",
                "care_level",
                "watering_text",
                "fertilization",
                "health_supported",
                "health_label_prefix",
            },
        )
        self.assertEqual(health.status_code, 200)
        self.assertEqual(health.json()["status"], "healthy")
        self.assertEqual(health.json()["disclaimer"], DISCLAIMER)
        self.assertEqual(unsupported.status_code, 200)
        self.assertFalse(unsupported.json()["confidence"] is not None)
        self.assertEqual(unsupported.json()["disclaimer"], DISCLAIMER)


if __name__ == "__main__":
    unittest.main()
