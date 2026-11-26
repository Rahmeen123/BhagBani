"""Prepare ground-truth crop observations and train the recommendation model."""

from __future__ import annotations

import argparse
import asyncio
from datetime import date, timedelta
import json
from pathlib import Path
import re
import sys
from typing import Any, Iterable

import httpx
import joblib
import numpy as np
import pandas as pd
import sklearn
from app.weather import WeatherServiceError, fetch_daily_weather
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    precision_recall_fscore_support,
)
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder


BACKEND_DIR = Path(__file__).resolve().parents[1]
DATASET_DIR = BACKEND_DIR / "dataset"
MODEL_DIR = BACKEND_DIR / "model"
WEATHER_FEATURES = ["Temperature", "Rainfall", "Humidity"]
BASE_FEATURE_COLUMNS = [
    "Latitude",
    "Longitude",
    "Province",
    "District",
    "Season",
    "Month",
]
NUMERIC_FEATURES = [
    "Latitude",
    "Longitude",
    "Month",
    *WEATHER_FEATURES,
]
CATEGORICAL_FEATURES = ["Province", "District", "Season"]
FEATURE_COLUMNS = [
    *BASE_FEATURE_COLUMNS,
    *WEATHER_FEATURES,
]
RAW_OUTPUT_COLUMNS = ["Date", *BASE_FEATURE_COLUMNS, "Crop"]
OUTPUT_COLUMNS = ["Date", *FEATURE_COLUMNS, "Crop"]
MAJOR_CROP_CLASSES = {
    "Rice",
    "Wheat",
    "Cotton",
    "Sugarcane",
    "Maize",
    "Sorghum",
    "Millet",
    "Barley",
    "Chickpea",
    "Groundnut",
    "Sesame",
    "Rapeseed Mustard",
    "Sunflower",
    "Tobacco",
}
MIN_CLASS_OBSERVATIONS = 50
POWER_LATITUDE_CELL_DEGREES = 0.5
POWER_LONGITUDE_CELL_DEGREES = 0.625
WEATHER_CACHE_SCHEMA_VERSION = 1
MAX_WEATHER_CONCURRENCY = 4
WEATHER_RETRIES = 3

# Match labels rather than the Land field: crop labels such as Eucalyptus may
# be associated with a Forest land-cover value in the source workbook.
NON_CROP_DESCRIPTIONS = {
    "water",
    "builtup",
    "built-up",
    "barren",
    "barrenland",
    "forest",
    "shrub",
    "shrubs",
    "grass",
    "grassland",
    "canal",
    "lake",
    "flood water",
    "grid station",
    "fish farm",
    "weeds",
    "fallow",
    "fallow (agriculture)",
    "fallowland",
    "road tree",
}
CROP_NAME_ALIASES = {
    "maize (corn)": "Maize",
    "okra": "Okra",
    "lady finger": "Okra",
    "ladyfinger": "Okra",
    "ground nuts/peanuts": "Groundnut",
    "sesame (til)": "Sesame",
    "bamboo": "Bamboo",
    "euclayptus": "Eucalyptus",
    "eucalyptus": "Eucalyptus",
    "brinjal": "Eggplant",
    "egg plant": "Eggplant",
    "alfalfa (lucerne)": "Alfalfa",
    "bittergourd": "Bitter Gourd",
    "cordamom": "Cardamom",
    "rhode grass": "Rhodes Grass",
    "rhodes grass": "Rhodes Grass",
    "barseem": "Berseem",
    "lobia beans": "Cowpea",
    "cow pea": "Cowpea",
    "datepalm": "Date Palm",
    "dates": "Date Palm",
    "taro root": "Taro",
    "rose flower": "Rose",
    "barrenland": "Barren",
    "builtup": "Built-up",
    "fallow": "Fallow (Agriculture)",
    "fallowland": "Fallow (Agriculture)",
}
REQUIRED_SOURCE_COLUMNS = {
    "Season",
    "Province",
    "District",
    "Date",
    "Latitude",
    "Longitude",
    "Land",
    "Description",
}


def _description_key(value: Any) -> str:
    """Normalize whitespace and case for description lookup."""
    cleaned = _clean_text(value)
    return "" if pd.isna(cleaned) else str(cleaned).casefold()


def _is_mixed_description(value: Any) -> bool:
    """Recognize intercropping labels without treating them as single crops."""
    key = _description_key(value)
    return (
        "mix" in key
        or "intercrop" in key
        or "inter crop" in key
        or " and " in f" {key} "
        or "," in key
    )


def _standardized_description(value: Any) -> str | None:
    cleaned = _clean_text(value)
    if pd.isna(cleaned):
        return None
    key = str(cleaned).casefold()
    return CROP_NAME_ALIASES.get(key, str(cleaned).title())


def build_description_mapping(descriptions: Iterable[Any]) -> pd.DataFrame:
    """Map every observed source label to its standard class and disposition."""
    raw_values = sorted(
        {str(value) for value in descriptions if not pd.isna(value)},
        key=lambda value: (value.strip().casefold(), value),
    )
    rows = []
    for raw_value in raw_values:
        key = _description_key(raw_value)
        if key in NON_CROP_DESCRIPTIONS:
            class_type = "non_crop"
            included = False
        elif _is_mixed_description(raw_value):
            class_type = "mixed_crop"
            included = False
        else:
            class_type = "crop"
            included = (
                _standardized_description(raw_value) in MAJOR_CROP_CLASSES
            )
        rows.append(
            {
                "Source_Description": raw_value,
                "Standardized_Description": _standardized_description(raw_value),
                "Class_Type": class_type,
                "Included_In_Training": included,
            }
        )
    return pd.DataFrame(rows)


def _clean_text(value: Any) -> Any:
    """Trim text fields and collapse whitespace without altering source data."""
    if pd.isna(value):
        return pd.NA
    cleaned = re.sub(r"\s+", " ", str(value)).strip()
    return cleaned if cleaned else pd.NA


def _parse_date(value: Any) -> pd.Timestamp:
    """Parse Excel serial dates and the workbook's day-first date strings."""
    if pd.isna(value):
        return pd.NaT
    if isinstance(value, (int, float)) and 20_000 <= value <= 80_000:
        return pd.Timestamp("1899-12-30") + timedelta(days=float(value))
    return pd.to_datetime(value, dayfirst=True, errors="coerce")


def prepare_dataset(source_path: Path) -> pd.DataFrame:
    """Create a crop-only training table; never edits the ground-truth workbook."""
    source = pd.read_excel(source_path, engine="openpyxl")
    source.columns = [str(column).strip() for column in source.columns]
    missing_columns = REQUIRED_SOURCE_COLUMNS.difference(source.columns)
    if missing_columns:
        missing = ", ".join(sorted(missing_columns))
        raise ValueError(f"Dataset is missing required columns: {missing}")

    for column in ("Season", "Province", "District", "Land", "Description"):
        source[column] = source[column].map(_clean_text)

    description_keys = source["Description"].map(_description_key)
    is_non_crop = description_keys.isin(NON_CROP_DESCRIPTIONS)
    is_mixed_crop = source["Description"].map(_is_mixed_description)
    source = source.loc[~is_non_crop & ~is_mixed_crop].copy()

    source["Date"] = source["Date"].map(_parse_date)
    source["Latitude"] = pd.to_numeric(source["Latitude"], errors="coerce")
    source["Longitude"] = pd.to_numeric(source["Longitude"], errors="coerce")
    source = source.dropna(
        subset=["Date", "Latitude", "Longitude", "Description"]
    )
    source = source.loc[
        source["Latitude"].between(-90, 90)
        & source["Longitude"].between(-180, 180)
    ].copy()

    for column in ("Season", "Province", "District"):
        source[column] = source[column].fillna("Unknown")

    source["Crop"] = source["Description"].map(_standardized_description)
    source = source.loc[source["Crop"].isin(MAJOR_CROP_CLASSES)].copy()
    class_counts = source["Crop"].value_counts()
    source = source.loc[
        source["Crop"].map(class_counts).ge(MIN_CLASS_OBSERVATIONS)
    ].copy()
    source["Month"] = source["Date"].dt.month.astype("int8")
    source["Date"] = source["Date"].dt.strftime("%Y-%m-%d")
    processed = source[RAW_OUTPUT_COLUMNS].reset_index(drop=True)
    if processed.empty:
        raise ValueError("No valid crop observations remain after preprocessing.")
    if processed["Crop"].nunique() < 2:
        raise ValueError("At least two crop classes are required to train a model.")
    return processed


def _power_cell(latitude: float, longitude: float) -> tuple[str, float, float]:
    """Share daily weather requests at POWER's approximate grid resolution."""
    latitude_index = round(latitude / POWER_LATITUDE_CELL_DEGREES)
    longitude_index = round(longitude / POWER_LONGITUDE_CELL_DEGREES)
    latitude_center = latitude_index * POWER_LATITUDE_CELL_DEGREES
    longitude_center = longitude_index * POWER_LONGITUDE_CELL_DEGREES
    key = f"{latitude_index}_{longitude_index}"
    return key, latitude_center, longitude_center


def _cache_file(cache_dir: Path, key: str) -> Path:
    return cache_dir / f"{key}.json"


def _read_weather_cache(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        entry = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Weather cache is invalid JSON: {path}") from exc
    if (
        not isinstance(entry, dict)
        or entry.get("schema_version") != WEATHER_CACHE_SCHEMA_VERSION
        or not isinstance(entry.get("observations"), dict)
        or not isinstance(entry.get("start_date"), str)
        or not isinstance(entry.get("end_date"), str)
    ):
        raise ValueError(f"Weather cache has an unsupported format: {path}")
    return entry


def _write_weather_cache(path: Path, entry: dict[str, Any]) -> None:
    temporary_path = path.with_suffix(".json.tmp")
    temporary_path.write_text(
        json.dumps(entry, separators=(",", ":"), allow_nan=False),
        encoding="utf-8",
    )
    temporary_path.replace(path)


async def _load_power_cell(
    key: str,
    latitude: float,
    longitude: float,
    period_start: date,
    period_end: date,
    cache_dir: Path,
    client: httpx.AsyncClient,
    semaphore: asyncio.Semaphore,
) -> str:
    """Read or fetch one spatial cell; each completed cell is resumable."""
    cache_path = _cache_file(cache_dir, key)
    cached = _read_weather_cache(cache_path)
    if cached is not None:
        if (
            cached.get("start_date", "") <= period_start.isoformat()
            and cached.get("end_date", "") >= period_end.isoformat()
        ):
            return key

    async with semaphore:
        for attempt in range(WEATHER_RETRIES):
            try:
                observations = await fetch_daily_weather(
                    latitude,
                    longitude,
                    period_start,
                    period_end,
                    client=client,
                )
                _write_weather_cache(
                    cache_path,
                    {
                        "schema_version": WEATHER_CACHE_SCHEMA_VERSION,
                        "latitude": latitude,
                        "longitude": longitude,
                        "start_date": period_start.isoformat(),
                        "end_date": period_end.isoformat(),
                        "observations": observations,
                    },
                )
                return key
            except WeatherServiceError as exc:
                if attempt + 1 == WEATHER_RETRIES:
                    raise WeatherServiceError(
                        f"NASA POWER cell {key} ({latitude}, {longitude}) "
                        f"failed after retries: {exc}"
                    ) from exc
                await asyncio.sleep(2**attempt)
    raise RuntimeError(f"Weather request retries exhausted for POWER cell {key}.")


def add_historical_weather(
    records: pd.DataFrame,
    cache_dir: Path,
) -> pd.DataFrame:
    """Join NASA daily weather for each observation date to the crop records.

    Requests are grouped to approximate NASA POWER grid cells, not by individual
    parcel, so nearby observations reuse the same point time series. The exact
    observation coordinates remain unchanged in the model feature table.
    """
    cache_dir.mkdir(parents=True, exist_ok=True)
    cells: dict[str, dict[str, Any]] = {}
    for row in records[["Latitude", "Longitude", "Date"]].itertuples(
        index=False
    ):
        key, latitude, longitude = _power_cell(row.Latitude, row.Longitude)
        cell = cells.setdefault(
            key,
            {
                "latitude": latitude,
                "longitude": longitude,
                "dates": [],
            },
        )
        cell["dates"].append(pd.Timestamp(row.Date).date())

    async def fetch_cells() -> None:
        semaphore = asyncio.Semaphore(MAX_WEATHER_CONCURRENCY)
        async with httpx.AsyncClient(timeout=httpx.Timeout(45.0)) as client:
            tasks = []
            for key, cell in cells.items():
                period_start = min(cell["dates"])
                period_end = max(cell["dates"])
                tasks.append(
                    asyncio.create_task(
                        _load_power_cell(
                            key,
                            cell["latitude"],
                            cell["longitude"],
                            period_start,
                            period_end,
                            cache_dir,
                            client,
                            semaphore,
                        )
                    )
                )
            failures: list[str] = []
            for index, completed in enumerate(asyncio.as_completed(tasks), 1):
                try:
                    await completed
                except WeatherServiceError as exc:
                    failures.append(str(exc))
                if index % 10 == 0 or index == len(tasks):
                    print(
                        f"Fetched NASA POWER weather for {index}/{len(tasks)} "
                        "spatial cells.",
                        flush=True,
                    )
            if failures:
                details = "; ".join(failures[:5])
                raise WeatherServiceError(
                    f"NASA POWER weather failed for {len(failures)} spatial "
                    f"cells. Successful cells were cached for retry. {details}"
                )

    asyncio.run(fetch_cells())

    cached_cells = {
        key: _read_weather_cache(_cache_file(cache_dir, key))
        for key in cells
    }
    temperatures: list[float] = []
    rainfall: list[float] = []
    humidity: list[float] = []
    for row in records[["Latitude", "Longitude", "Date"]].itertuples(
        index=False
    ):
        key, _, _ = _power_cell(row.Latitude, row.Longitude)
        cache = cached_cells[key]
        if cache is None:
            raise RuntimeError(f"Weather cache was not written for cell {key}.")
        date_key = pd.Timestamp(row.Date).strftime("%Y%m%d")
        daily = cache["observations"].get(date_key, {})
        temperatures.append(
            daily.get("T2M")
            if daily.get("T2M") is not None
            else np.nan
        )
        rainfall.append(
            daily.get("PRECTOTCORR")
            if daily.get("PRECTOTCORR") is not None
            else np.nan
        )
        humidity.append(
            daily.get("RH2M")
            if daily.get("RH2M") is not None
            else np.nan
        )

    enriched = records.copy()
    enriched["Temperature"] = pd.to_numeric(temperatures, errors="coerce")
    enriched["Rainfall"] = pd.to_numeric(rainfall, errors="coerce")
    enriched["Humidity"] = pd.to_numeric(humidity, errors="coerce")
    if not enriched["Temperature"].notna().any():
        raise ValueError("NASA POWER returned no usable training temperatures.")
    if not enriched["Rainfall"].notna().any():
        raise ValueError("NASA POWER returned no usable training rainfall.")
    return enriched[OUTPUT_COLUMNS].reset_index(drop=True)


def build_pipeline(numeric_features: list[str] | None = None) -> Pipeline:
    """Build imputation/one-hot encoding and a class-balanced random forest."""
    numeric_features = numeric_features or NUMERIC_FEATURES
    numeric = Pipeline(
        steps=[("imputer", SimpleImputer(strategy="median"))]
    )
    categorical = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value="Unknown")),
            ("encoder", OneHotEncoder(handle_unknown="ignore")),
        ]
    )
    features = ColumnTransformer(
        transformers=[
            ("numeric", numeric, numeric_features),
            ("categorical", categorical, CATEGORICAL_FEATURES),
        ],
        remainder="drop",
    )
    classifier = RandomForestClassifier(
        n_estimators=120,
        max_depth=24,
        min_samples_leaf=4,
        max_samples=0.8,
        class_weight="balanced_subsample",
        random_state=42,
        n_jobs=2,
    )
    return Pipeline(
        steps=[("features", features), ("classifier", classifier)]
    )


def _stratified_holdout_indices(
    labels: pd.Series,
    test_fraction: float = 0.2,
    random_state: int = 42,
) -> tuple[list[int], list[int]]:
    """Split each multi-record class while preserving train/test examples."""
    generator = np.random.default_rng(random_state)
    training_indices: list[int] = []
    holdout_indices: list[int] = []
    for _, class_labels in labels.groupby(labels, sort=True):
        indices = class_labels.index.to_numpy(copy=True)
        if len(indices) < 2:
            raise ValueError(
                "Stratified holdout requires at least two records per class."
            )
        generator.shuffle(indices)
        holdout_count = max(1, int(len(indices) * test_fraction))
        holdout_count = min(holdout_count, len(indices) - 1)
        holdout_indices.extend(indices[:holdout_count].tolist())
        training_indices.extend(indices[holdout_count:].tolist())
    return sorted(training_indices), sorted(holdout_indices)


def _input_feature_importance(
    model: Pipeline,
    feature_columns: list[str],
) -> list[dict[str, float | str]]:
    """Aggregate one-hot feature importances back to source input columns."""
    transformed_names = (
        model.named_steps["features"].get_feature_names_out()
    )
    importances = model.named_steps["classifier"].feature_importances_
    grouped = {feature: 0.0 for feature in feature_columns}
    for transformed_name, importance in zip(transformed_names, importances):
        name = transformed_name.split("__", maxsplit=1)[-1]
        source_feature = next(
            (
                feature
                for feature in feature_columns
                if name == feature or name.startswith(f"{feature}_")
            ),
            None,
        )
        if source_feature is None:
            raise ValueError(
                f"Unable to map model feature importance {transformed_name!r}."
            )
        grouped[source_feature] += float(importance)
    return [
        {"feature": feature, "importance": importance}
        for feature, importance in sorted(
            grouped.items(), key=lambda item: item[1], reverse=True
        )
    ]


def train(
    source_path: Path,
    processed_path: Path,
    model_dir: Path,
    weather_cache_dir: Path = DATASET_DIR / "nasa_power_weather_cache",
    mapping_path: Path = DATASET_DIR / "description_mapping.csv",
    report_path: Path = MODEL_DIR / "training_report.json",
) -> None:
    """Enrich crop records, evaluate, fit, and save model/report artifacts."""
    previous_report = None
    if report_path.is_file():
        previous_report = json.loads(report_path.read_text(encoding="utf-8"))

    processed = prepare_dataset(source_path)
    source_descriptions = pd.read_excel(
        source_path,
        engine="openpyxl",
        usecols=["Description"],
    )["Description"]
    description_mapping = build_description_mapping(source_descriptions)
    description_mapping["Included_In_Training"] = (
        description_mapping["Class_Type"].eq("crop")
        & description_mapping["Standardized_Description"].isin(
            set(processed["Crop"])
        )
    )
    processed = add_historical_weather(processed, weather_cache_dir)
    model_feature_columns = [
        column
        for column in FEATURE_COLUMNS
        if column != "Humidity" or processed["Humidity"].notna().any()
    ]
    numeric_features = [
        column for column in NUMERIC_FEATURES if column in model_feature_columns
    ]
    X = processed[model_feature_columns]
    y = processed["Crop"]

    # Weather features are joined by each observation's coordinates and date;
    # optional humidity is used only when NASA provides at least some values.
    model = build_pipeline(numeric_features)

    class_counts = y.value_counts()
    evaluable = y.map(class_counts).ge(2)
    X_evaluable = X.loc[evaluable]
    y_evaluable = y.loc[evaluable]
    if y_evaluable.nunique() < 2:
        raise ValueError(
            "At least two crop classes with two or more records are required "
            "for holdout evaluation."
        )
    training_indices, holdout_indices = _stratified_holdout_indices(
        y_evaluable
    )
    X_train = X.loc[training_indices]
    X_test = X.loc[holdout_indices]
    y_train = y.loc[training_indices]
    y_test = y.loc[holdout_indices]
    evaluation_model = build_pipeline(numeric_features)
    evaluation_model.fit(X_train, y_train)
    predictions = evaluation_model.predict(X_test)
    evaluated_classes = sorted(y_evaluable.unique().tolist())
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_test,
        predictions,
        labels=evaluated_classes,
        average="macro",
        zero_division=0,
    )
    matrix = confusion_matrix(
        y_test,
        predictions,
        labels=evaluated_classes,
    )

    model.fit(X, y)
    feature_importance = _input_feature_importance(
        model, model_feature_columns
    )
    metrics = {
        "accuracy": float(accuracy_score(y_test, predictions)),
        "precision_macro": float(precision),
        "recall_macro": float(recall),
        "f1_macro": float(f1),
    }
    comparison = None
    if previous_report is not None:
        previous_evaluation = previous_report.get("evaluation", {})
        previous_metrics = {
            metric: float(previous_evaluation[metric])
            for metric in metrics
            if metric in previous_evaluation
        }
        if previous_metrics:
            comparison = {
                "previous_model": {
                    "final_crop_classes": previous_report.get(
                        "final_crop_classes"
                    ),
                    "training_rows": previous_report.get("training_rows"),
                    "metrics": previous_metrics,
                },
                "new_model": {
                    "final_crop_classes": int(y.nunique()),
                    "training_rows": int(len(processed)),
                    "metrics": metrics,
                },
                "metric_deltas_new_minus_previous": {
                    metric: metrics[metric] - previous_metrics[metric]
                    for metric in metrics
                    if metric in previous_metrics
                },
                "note": (
                    "The previous evaluation covered a broader crop set; "
                    "metrics are not a like-for-like benchmark."
                ),
            }

    processed_path.parent.mkdir(parents=True, exist_ok=True)
    model_dir.mkdir(parents=True, exist_ok=True)
    mapping_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    processed.to_csv(processed_path, index=False, encoding="utf-8")
    description_mapping.to_csv(mapping_path, index=False, encoding="utf-8")
    joblib.dump(model, model_dir / "crop_model.pkl", compress=3)
    joblib.dump(
        {
            "feature_columns": model_feature_columns,
            "context_records": processed[BASE_FEATURE_COLUMNS].copy(),
            "training_rows": len(processed),
            "crop_classes": sorted(y.unique().tolist()),
            "class_distribution": {
                str(crop): int(count)
                for crop, count in class_counts.sort_index().items()
            },
            "humidity_used": "Humidity" in model_feature_columns,
            "pandas_version": pd.__version__,
            "scikit_learn_version": sklearn.__version__,
        },
        model_dir / "preprocessors.pkl",
        compress=3,
    )

    report = {
        "source_dataset": str(source_path),
        "training_dataset": str(processed_path),
        "mapping_file": str(mapping_path),
        "training_rows": int(len(processed)),
        "final_crop_classes": int(y.nunique()),
        "minimum_class_observations": MIN_CLASS_OBSERVATIONS,
        "requested_crop_classes": sorted(MAJOR_CROP_CLASSES),
        "requested_classes_removed_by_minimum": sorted(
            MAJOR_CROP_CLASSES.difference(class_counts.index)
        ),
        "class_distribution": {
            str(crop): int(count)
            for crop, count in class_counts.sort_index().items()
        },
        "evaluation": {
            "method": "Stratified 80/20 holdout; singleton classes remain in final training but are not evaluated.",
            "training_rows": int(len(X_train)),
            "holdout_rows": int(len(X_test)),
            "evaluated_classes": evaluated_classes,
            **metrics,
            "confusion_matrix_labels": evaluated_classes,
            "confusion_matrix": matrix.astype(int).tolist(),
        },
        "feature_importance": feature_importance,
        "comparison_with_previous_model": comparison,
    }
    report_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Processed crop observations: {len(processed):,}")
    print(f"Crop classes: {y.nunique():,}")
    print(
        "Holdout metrics: "
        f"accuracy={report['evaluation']['accuracy']:.4f}, "
        f"precision={precision:.4f}, recall={recall:.4f}, f1={f1:.4f}"
    )
    print(f"Model features: {', '.join(model_feature_columns)}")
    print(f"Processed dataset: {processed_path}")
    print(f"Description mapping: {mapping_path}")
    print(f"Training report: {report_path}")
    print(f"Model artifacts: {model_dir}")


def main() -> None:
    default_source = DATASET_DIR / "original_ground_truth_dataset.xlsx"
    if not default_source.exists():
        default_source = (
            BACKEND_DIR.parent
            / "dataset for crop recommendation"
            / "Dataset.xlsx"
        )

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=default_source,
        help="Original ground-truth Excel workbook (read-only input).",
    )
    parser.add_argument(
        "--processed-output",
        type=Path,
        default=DATASET_DIR / "processed_crop_dataset.csv",
    )
    parser.add_argument("--model-dir", type=Path, default=MODEL_DIR)
    parser.add_argument(
        "--weather-cache",
        type=Path,
        default=DATASET_DIR / "nasa_power_weather_cache",
        help="Directory for resumable NASA POWER daily weather responses.",
    )
    parser.add_argument(
        "--mapping-output",
        type=Path,
        default=DATASET_DIR / "description_mapping.csv",
    )
    parser.add_argument(
        "--report-output",
        type=Path,
        default=MODEL_DIR / "training_report.json",
    )
    args = parser.parse_args()

    if not args.source.is_file():
        parser.error(f"Source dataset does not exist: {args.source}")
    try:
        train(
            args.source,
            args.processed_output,
            args.model_dir,
            args.weather_cache,
            args.mapping_output,
            args.report_output,
        )
    except Exception as exc:
        print(f"Training failed: {exc}", file=sys.stderr)
        raise


if __name__ == "__main__":
    main()
