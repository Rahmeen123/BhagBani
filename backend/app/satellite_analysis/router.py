"""HTTP endpoint for Sentinel Hub satellite land analysis."""

from __future__ import annotations

import logging

from fastapi import APIRouter

from app.satellite_analysis.models import LandAnalysisRequest, LandAnalysisResponse
from app.satellite_analysis.service import (
    SentinelHubConfigurationError,
    SentinelHubServiceError,
    SentinelHubStatisticalService,
)


logger = logging.getLogger(__name__)
router = APIRouter(tags=["satellite-analysis"])


@router.post(
    "/analyze-land",
    response_model=LandAnalysisResponse,
    summary="Analyze vegetation within a farm boundary",
    description=(
        "Returns Sentinel-2 L2A NDVI vegetation metrics for a GeoJSON Polygon. "
        "Cloudy, unavailable, or failed satellite analyses are marked inconclusive."
    ),
)
async def analyze_land(body: LandAnalysisRequest) -> LandAnalysisResponse:
    try:
        return await SentinelHubStatisticalService().analyze(body)
    except (SentinelHubConfigurationError, SentinelHubServiceError):
        logger.exception("Satellite land analysis is unavailable.")
        return LandAnalysisResponse.inconclusive()
