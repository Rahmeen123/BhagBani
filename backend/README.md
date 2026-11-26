# Crop recommendation backend

This FastAPI service trains a location-, season-, and weather-aware crop
classifier from the supplied ground-truth workbook and uses NASA POWER for
weather during both training and prediction. The source workbook is copied
here unchanged; training writes a separate crop-only CSV and model artifacts.

## Dataset and model

The original dataset is `backend/dataset/original_ground_truth_dataset.xlsx`.
The source workbook is read-only during preprocessing. Description values are
standardized using a generated mapping. Training is restricted to Rice, Wheat,
Cotton, Sugarcane, Maize, Sorghum, Millet, Barley, Chickpea, Groundnut,
Sesame, Rapeseed Mustard, Sunflower, and Tobacco; classes with fewer than 50
valid observations are also excluded. Mixed/intercrop, fruit, vegetable, tree,
ornamental, and non-crop labels are not trained. Aliases such as `Maize
(Corn)`, `Ground nuts/Peanuts`, and `Sesame (Til)` map to canonical labels.
The source workbook is never modified. Dates are parsed from Excel serial
values or day-first date strings, and Month is derived from Date.

For each crop observation, training joins NASA POWER daily temperature
(`T2M`), rainfall (`PRECTOTCORR`), and humidity (`RH2M` when available) for
that observation's date. Requests are grouped into approximate POWER
0.5-degree latitude by 0.625-degree longitude cells and cached individually,
so completed work is reused if training is retried. The exact coordinates
remain model features; missing daily values are imputed by the training
pipeline, and humidity is included only when NASA provides it.

The Random Forest uses Latitude, Longitude, Province, District, Season, Month,
Temperature, Rainfall, and Humidity when available. Categorical fields are
one-hot encoded. The API derives Province/District from the nearest crop
observation and chooses the most common historical season for that region and
month (falling back to the wider province or dataset).

## Run on Windows

From `backend`:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m model.train_model
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

By default, training reads `backend/dataset/original_ground_truth_dataset.xlsx`
and requests the historical NASA POWER data needed for training. Completed
weather cells are cached in `backend/dataset/nasa_power_weather_cache/`.
Training creates:

- `backend/dataset/processed_crop_dataset.csv`
- `backend/dataset/description_mapping.csv`
- `backend/model/crop_model.pkl`
- `backend/model/preprocessors.pkl`
- `backend/model/training_report.json`

The report includes the final class distribution, stratified 80/20 holdout
accuracy, macro precision/recall/F1, confusion matrix, grouped feature
importance, and metrics compared with the previous report. The comparison
notes that the previous model covered a broader set of classes, so the scores
are not a like-for-like benchmark.

Override locations with `--source`, `--processed-output`, `--model-dir`, and
`--weather-cache`; use `--mapping-output` and `--report-output` to change the
mapping and report paths. Set `CROP_MODEL_DIR` to use another model directory.
Set `CORS_ORIGINS` to a comma-separated allowlist when serving Flutter Web;
native Flutter clients do not require browser CORS.

## Model experiments

The optional experiment suite compares Random Forest parameter/weight
settings with Gradient Boosting and XGBoost using stratified cross-validation.
It uses the already processed dataset and writes `model/experiments_report.json`
without replacing the deployed model. XGBoost is intentionally kept out of
runtime requirements:

```powershell
python -m pip install -r requirements-experiments.txt
python -m model.run_experiments
```

## API

The model and preprocessing pipeline are loaded once during API startup and
reused for each request. The endpoint fetches recent NASA POWER data, assembles
the same numeric and categorical input features used by training, then returns
the top three predictions.

`POST /recommend-crop`

```json
{
  "latitude": 31.5204,
  "longitude": 74.3587
}
```

Response:

```json
{
  "location": "Lahore, Punjab",
  "weather": {
    "temperature": 30.0,
    "rainfall": 1.2,
    "humidity": 58.0
  },
  "recommendations": [
    {"crop_name": "Rice", "confidence_percentage": 42.5},
    {"crop_name": "Maize", "confidence_percentage": 21.3},
    {"crop_name": "Wheat", "confidence_percentage": 12.7}
  ]
}
```

Coordinates must be decimal degrees (`latitude`: -90 to 90,
`longitude`: -180 to 180). Invalid input returns HTTP 422. NASA POWER's latest
usable daily temperature/rainfall reading from recent periods (up to 180 days)
is used for inference; humidity is nullable when unavailable. Weather-service
failures return HTTP 502, while model prediction failures return HTTP 500.
`GET /health` checks service availability. Interactive API documentation is
available at `/docs` and `/redoc`. Flutter mobile clients can POST the same
JSON over HTTPS; browser CORS configuration is only required for Flutter Web.

Weather inputs are historical observations, not a forecast. Model confidence
is a classifier probability and should not be interpreted as a guarantee of
suitability.

The serialized artifacts are version-checked against the installed Pandas and
scikit-learn versions. Re-run training after changing either dependency.

## Satellite land analysis

`POST /analyze-land` is a separate Sentinel Hub Statistical API integration; it
does not use or change the crop recommendation model or endpoint. Configure
`SENTINEL_HUB_CLIENT_ID` and `SENTINEL_HUB_CLIENT_SECRET` in the backend
environment. Never put these credentials in the Flutter app.

Request:

```json
{
  "geometry": {
    "type": "Polygon",
    "coordinates": [[[74.35, 31.52], [74.351, 31.52], [74.351, 31.521], [74.35, 31.521], [74.35, 31.52]]]
  },
  "start_date": "2026-11-01",
  "end_date": "2026-11-20"
}
```

Coordinates use GeoJSON longitude/latitude order. The polygon must be valid,
closed, between 0.01 and 1,000 hectares, and use a date range of at most 366
days ending no later than today. Invalid requests return HTTP 422.

Response:

```json
{
  "vegetation_percentage": 68.2,
  "bare_land_percentage": 18.4,
  "cloud_percentage": 7.1,
  "average_ndvi": 0.47,
  "analysis_status": "conclusive",
  "observation_date": "2026-11-18"
}
```

Percentages and NDVI are `null` when no usable observation is available.
`analysis_status` is `inconclusive` when there is no data, provider access
fails, or cloud coverage reaches 60 percent. Land cover is an NDVI-derived
estimate and does not identify a specific crop or confirm a plantation.
