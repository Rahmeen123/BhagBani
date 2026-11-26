"""API models for the satellite land-analysis contract."""

from __future__ import annotations

from datetime import date, timedelta
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.satellite_analysis.geometry import PolygonValidationError, validate_polygon


MAX_DATE_RANGE_DAYS = 366
MIN_AREA_HECTARES = 0.01
MAX_AREA_HECTARES = 1_000


class AnalysisStatus(str, Enum):
    CONCLUSIVE = "conclusive"
    INCONCLUSIVE = "inconclusive"


class LandAnalysisRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    geometry: dict[str, Any] = Field(description="Farm boundary as a GeoJSON Polygon.")
    start_date: date
    end_date: date

    @model_validator(mode="after")
    def validate_analysis_request(self) -> LandAnalysisRequest:
        try:
            area_hectares = validate_polygon(self.geometry)
        except PolygonValidationError as exc:
            raise ValueError(str(exc)) from exc
        if not MIN_AREA_HECTARES <= area_hectares <= MAX_AREA_HECTARES:
            raise ValueError(
                f"Polygon area must be between {MIN_AREA_HECTARES:g} and "
                f"{MAX_AREA_HECTARES:g} hectares."
            )
        if self.end_date < self.start_date:
            raise ValueError("end_date must not be earlier than start_date.")
        if (self.end_date - self.start_date).days + 1 > MAX_DATE_RANGE_DAYS:
            raise ValueError(f"Date range must not exceed {MAX_DATE_RANGE_DAYS} days.")
        if self.end_date > date.today():
            raise ValueError("Dates must not be in the future.")
        return self


class LandAnalysisResponse(BaseModel):
    vegetation_percentage: float | None = Field(ge=0, le=100)
    bare_land_percentage: float | None = Field(ge=0, le=100)
    cloud_percentage: float | None = Field(ge=0, le=100)
    average_ndvi: float | None = Field(ge=-1, le=1)
    analysis_status: AnalysisStatus
    observation_date: date | None

    @classmethod
    def inconclusive(cls) -> LandAnalysisResponse:
        return cls(
            vegetation_percentage=None,
            bare_land_percentage=None,
            cloud_percentage=None,
            average_ndvi=None,
            analysis_status=AnalysisStatus.INCONCLUSIVE,
            observation_date=None,
        )


def inclusive_time_range(start_date: date, end_date: date) -> dict[str, str]:
    """Build the half-open Sentinel Hub time range for inclusive user dates."""
    return {
        "from": f"{start_date.isoformat()}T00:00:00Z",
        "to": f"{(end_date + timedelta(days=1)).isoformat()}T00:00:00Z",
    }
