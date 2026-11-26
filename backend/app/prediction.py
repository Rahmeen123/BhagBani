"""Load the trained model and build location/season-aware crop predictions."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.pipeline import Pipeline


@dataclass(frozen=True)
class CropPrediction:
    crop: str
    confidence: float


@dataclass(frozen=True)
class RecommendationResult:
    location: str
    province: str
    district: str
    season: str
    month: int
    nearest_observation_distance_km: float
    recommendations: list[CropPrediction]


class CropRecommender:
    """Predict crops using the nearest training region and historical season."""

    def __init__(self, model: Pipeline, context_records: pd.DataFrame) -> None:
        self._model = model
        self._context = context_records.reset_index(drop=True)
        self._latitudes = np.radians(self._context["Latitude"].to_numpy(float))
        self._longitudes = np.radians(self._context["Longitude"].to_numpy(float))

    @classmethod
    def load(cls, model_dir: Path) -> "CropRecommender":
        model_path = model_dir / "crop_model.pkl"
        metadata_path = model_dir / "preprocessors.pkl"
        if not model_path.is_file() or not metadata_path.is_file():
            raise FileNotFoundError(
                "Crop model artifacts are missing. Run "
                "`python -m model.train_model` from the backend directory."
            )
        model = joblib.load(model_path)
        metadata: dict[str, Any] = joblib.load(metadata_path)
        expected_versions = {
            "pandas_version": pd.__version__,
            "scikit_learn_version": sklearn.__version__,
        }
        for key, installed_version in expected_versions.items():
            artifact_version = metadata.get(key)
            if artifact_version != installed_version:
                raise RuntimeError(
                    f"Model artifact {key} is {artifact_version!r}, but the "
                    f"installed version is {installed_version!r}. Retrain the "
                    "model or install the matching dependencies."
                )
        feature_columns = metadata.get("feature_columns")
        if not isinstance(feature_columns, list) or not {
            "Temperature",
            "Rainfall",
        }.issubset(feature_columns):
            raise ValueError(
                "Loaded model was not trained with historical weather. "
                "Run `python -m model.train_model` to rebuild it."
            )
        records = metadata.get("context_records")
        if not isinstance(model, Pipeline) or not isinstance(records, pd.DataFrame):
            raise ValueError("Crop model artifacts have an invalid format.")
        if records.empty:
            raise ValueError("Crop model metadata has no location records.")
        return cls(model, records)

    def recommend(
        self,
        latitude: float,
        longitude: float,
        month: int,
        temperature: float,
        rainfall: float,
        humidity: float | None,
        top_k: int = 3,
    ) -> RecommendationResult:
        """Resolve local context, then return the highest model probabilities."""
        distances = self._distances_km(latitude, longitude)
        nearest_index = int(np.argmin(distances))
        nearest = self._context.iloc[nearest_index]
        province = str(nearest["Province"])
        district = str(nearest["District"])

        region = self._context.loc[
            (self._context["Province"] == province)
            & (self._context["District"] == district)
        ]
        season = self._historical_season(region, province, month)
        features = pd.DataFrame(
            [
                {
                    "Latitude": latitude,
                    "Longitude": longitude,
                    "Province": province,
                    "District": district,
                    "Season": season,
                    "Month": month,
                    "Temperature": temperature,
                    "Rainfall": rainfall,
                    "Humidity": (
                        humidity if humidity is not None else np.nan
                    ),
                }
            ]
        )

        probabilities = self._model.predict_proba(features)[0]
        classes = self._model.named_steps["classifier"].classes_
        best_indices = np.argsort(probabilities)[::-1][:top_k]
        recommendations = [
            CropPrediction(
                crop=str(classes[index]),
                confidence=round(float(probabilities[index]) * 100, 2),
            )
            for index in best_indices
        ]
        return RecommendationResult(
            location=f"{district}, {province}",
            province=province,
            district=district,
            season=season,
            month=month,
            nearest_observation_distance_km=round(
                float(distances[nearest_index]), 2
            ),
            recommendations=recommendations,
        )

    def _historical_season(
        self,
        region: pd.DataFrame,
        province: str,
        month: int,
    ) -> str:
        """Prefer the district's season for this month; fall back by province."""
        district_month = region.loc[region["Month"] == month, "Season"]
        if not district_month.empty:
            return self._mode(district_month)

        province_month = self._context.loc[
            (self._context["Province"] == province)
            & (self._context["Month"] == month),
            "Season",
        ]
        if not province_month.empty:
            return self._mode(province_month)

        month_seasons = self._context.loc[
            self._context["Month"] == month, "Season"
        ]
        if not month_seasons.empty:
            return self._mode(month_seasons)
        return self._mode(region["Season"])

    @staticmethod
    def _mode(values: pd.Series) -> str:
        counts = values.value_counts()
        return str(sorted(counts[counts == counts.max()].index)[0])

    def _distances_km(self, latitude: float, longitude: float) -> np.ndarray:
        """Compute vectorized great-circle distances to the training records."""
        lat = np.radians(latitude)
        lon = np.radians(longitude)
        delta_lat = self._latitudes - lat
        delta_lon = self._longitudes - lon
        haversine = (
            np.sin(delta_lat / 2) ** 2
            + np.cos(lat) * np.cos(self._latitudes) * np.sin(delta_lon / 2) ** 2
        )
        return 2 * 6371.0088 * np.arcsin(np.sqrt(np.clip(haversine, 0, 1)))
