"""HTTP API for location-based crop recommendations."""

from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import datetime
import logging
import os
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field
from starlette.middleware.cors import CORSMiddleware

from app.prediction import CropRecommender
from app.satellite_analysis.router import router as satellite_analysis_router
from app.weather import WeatherServiceError, fetch_weather


BACKEND_DIR = Path(__file__).resolve().parents[1]
MODEL_DIR = Path(os.getenv("CROP_MODEL_DIR", BACKEND_DIR / "model"))
logger = logging.getLogger(__name__)


class RecommendationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    latitude: float = Field(
        ge=-90,
        le=90,
        allow_inf_nan=False,
        description="Latitude in decimal degrees, from -90 to 90.",
        examples=[31.5204],
    )
    longitude: float = Field(
        ge=-180,
        le=180,
        allow_inf_nan=False,
        description="Longitude in decimal degrees, from -180 to 180.",
        examples=[74.3587],
    )


class WeatherResponse(BaseModel):
    temperature: float = Field(
        description="Latest usable NASA POWER daily temperature in Celsius."
    )
    rainfall: float = Field(
        description="Latest usable NASA POWER daily rainfall in millimeters."
    )
    humidity: float | None = Field(
        description="NASA POWER relative humidity percentage, or null."
    )


class CropRecommendation(BaseModel):
    crop_name: str = Field(description="Standardized predicted crop class.")
    confidence_percentage: float = Field(
        ge=0,
        le=100,
        description="Classifier probability expressed as a percentage.",
    )


class RecommendationResponse(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "location": "Lahore, Punjab",
                "weather": {
                    "temperature": 30.0,
                    "rainfall": 1.2,
                    "humidity": 58.0,
                },
                "recommendations": [
                    {
                        "crop_name": "Rice",
                        "confidence_percentage": 42.5,
                    },
                    {
                        "crop_name": "Maize",
                        "confidence_percentage": 21.3,
                    },
                    {
                        "crop_name": "Wheat",
                        "confidence_percentage": 12.7,
                    },
                ],
            }
        }
    )

    location: str
    weather: WeatherResponse
    recommendations: list[CropRecommendation]


@asynccontextmanager
async def lifespan(application: FastAPI):
    """Load model artifacts once per application process."""
    application.state.recommender = CropRecommender.load(MODEL_DIR)
    yield


app = FastAPI(
    title="Baghbani Crop Recommendation API",
    version="1.0.0",
    description=(
        "Recommends crops from historical ground-truth crop observations "
        "and recent NASA POWER weather features."
    ),
    lifespan=lifespan,
)
app.include_router(satellite_analysis_router)

cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "").split(",")
    if origin.strip()
]
if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type", "Authorization"],
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post(
    "/recommend-crop",
    response_model=RecommendationResponse,
    summary="Recommend crops for a location",
    description=(
        "Fetches recent NASA POWER weather for the supplied coordinates and "
        "returns the top three crop predictions. Coordinates must be decimal "
        "degrees. Humidity may be null when NASA POWER has no usable reading."
    ),
    responses={
        500: {"description": "The crop recommendation could not be generated."},
        502: {"description": "NASA POWER weather data is unavailable."},
    },
)
async def recommend_crop(
    body: RecommendationRequest,
    request: Request,
) -> RecommendationResponse:
    """Fetch weather and rank crops for the user's coordinates."""
    month = datetime.now(ZoneInfo("Asia/Karachi")).month
    try:
        weather = await fetch_weather(
            latitude=body.latitude,
            longitude=body.longitude,
            month=month,
        )
    except WeatherServiceError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    try:
        result = request.app.state.recommender.recommend(
            latitude=body.latitude,
            longitude=body.longitude,
            month=month,
            temperature=weather.temperature_c,
            rainfall=weather.rainfall_mm,
            humidity=weather.humidity_percent,
            top_k=3,
        )
    except Exception as exc:
        logger.exception("Crop prediction failed for supplied coordinates.")
        raise HTTPException(
            status_code=500,
            detail="The crop recommendation could not be generated.",
        ) from exc

    return RecommendationResponse(
        location=result.location,
        weather=WeatherResponse(
            temperature=weather.temperature_c,
            rainfall=weather.rainfall_mm,
            humidity=weather.humidity_percent,
        ),
        recommendations=[
            CropRecommendation(
                crop_name=item.crop,
                confidence_percentage=item.confidence,
            )
            for item in result.recommendations
        ],
    )
