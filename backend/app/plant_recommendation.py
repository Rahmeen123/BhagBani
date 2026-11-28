from __future__ import annotations

import csv
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, ConfigDict


router = APIRouter()

SunlightInput = Literal["Full Sun", "Partial Sun", "Low Light"]
CareLevelInput = Literal["Low", "Regular", "High"]
SoilInput = Literal["well-drained", "sandy", "loamy", "moist", "acidic"]
GrowthInput = Literal["Fast", "Moderate", "Slow"]

SUNLIGHT_DATASET_VALUE = {
    "Full Sun": "full sunlight",
    "Partial Sun": "partial sunlight",
    "Low Light": "indirect sunlight",
}
CARE_LEVELS = ("low", "regular", "high")


class PlantRecommendationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    sunlight: SunlightInput
    care_level: CareLevelInput
    soil: SoilInput | None = None
    growth: GrowthInput | None = None


class PlantRecord(BaseModel):
    name: str
    growth: str
    soil: str
    sunlight: str
    care_level: CareLevelInput
    watering_text: str
    fertilization: str
    health_supported: bool
    health_label_prefix: str


class PlantRecommendationResponse(BaseModel):
    recommendations: list[PlantRecord]


class PlantRecommendationService:
    def __init__(self, plants: list[PlantRecord]) -> None:
        self._plants = plants

    @classmethod
    def load(cls, path: Path) -> PlantRecommendationService:
        with path.open(encoding="utf-8", newline="") as csv_file:
            reader = csv.DictReader(csv_file)
            required = set(PlantRecord.model_fields)
            if reader.fieldnames is None or not required.issubset(reader.fieldnames):
                raise ValueError("The cleaned plant dataset has invalid columns.")
            plants = [PlantRecord.model_validate(row) for row in reader]
        if not plants:
            raise ValueError("The cleaned plant dataset does not contain plants.")
        return cls(plants)

    def recommend(self, request: PlantRecommendationRequest) -> list[PlantRecord]:
        sunlight = SUNLIGHT_DATASET_VALUE[request.sunlight]
        care_level = request.care_level.casefold()
        baseline = [
            plant
            for plant in self._plants
            if plant.sunlight.casefold() == sunlight
            and plant.care_level.casefold() == care_level
        ]

        exact = self._apply_optional_filters(baseline, request)
        if exact:
            return exact

        without_growth = self._apply_optional_filters(
            baseline, request, include_growth=False
        )
        if without_growth:
            return without_growth

        if request.soil is not None:
            without_soil = self._apply_optional_filters(
                baseline, request, include_soil=False, include_growth=False
            )
            if without_soil:
                return without_soil

        care_index = CARE_LEVELS.index(care_level)
        adjacent_care_levels = CARE_LEVELS[
            max(0, care_index - 1) : min(len(CARE_LEVELS), care_index + 2)
        ]
        return [
            plant
            for plant in self._plants
            if plant.sunlight.casefold() == sunlight
            and plant.care_level.casefold() in adjacent_care_levels
            and plant.care_level.casefold() != care_level
        ]

    @staticmethod
    def _apply_optional_filters(
        plants: list[PlantRecord],
        request: PlantRecommendationRequest,
        *,
        include_soil: bool = True,
        include_growth: bool = True,
    ) -> list[PlantRecord]:
        return [
            plant
            for plant in plants
            if (
                not include_soil
                or request.soil is None
                or plant.soil.casefold() == request.soil.casefold()
            )
            and (
                not include_growth
                or request.growth is None
                or plant.growth.casefold() == request.growth.casefold()
            )
        ]


@router.post(
    "/recommend",
    response_model=PlantRecommendationResponse,
    summary="Recommend plants using exact care-preference filters",
)
async def recommend_plants(
    body: PlantRecommendationRequest,
    request: Request,
) -> PlantRecommendationResponse:
    service: PlantRecommendationService = request.app.state.plant_recommender
    return PlantRecommendationResponse(
        recommendations=service.recommend(body)
    )
