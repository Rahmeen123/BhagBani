"""NASA POWER daily historical and recent weather data."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
import math
from typing import Any

import httpx


NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"
WEATHER_PARAMETERS = ("T2M", "PRECTOTCORR", "RH2M")


class WeatherServiceError(RuntimeError):
    """Raised when NASA POWER cannot provide usable weather data."""


@dataclass(frozen=True)
class WeatherSnapshot:
    temperature_c: float
    rainfall_mm: float
    humidity_percent: float | None
    month: int
    period_start: str
    period_end: str
    days_averaged: int


async def fetch_weather(
    latitude: float,
    longitude: float,
    month: int,
    client: httpx.AsyncClient | None = None,
) -> WeatherSnapshot:
    """Fetch the latest usable daily values available from recent periods."""
    owns_client = client is None
    if client is None:
        client = httpx.AsyncClient(timeout=httpx.Timeout(40.0))

    today = date.today()
    try:
        for days_back in range(1, 181, 30):
            period_end = today - timedelta(days=days_back)
            period_start = period_end - timedelta(days=29)
            daily = await fetch_daily_weather(
                latitude,
                longitude,
                period_start,
                period_end,
                client=client,
            )
            valid_dates = sorted(
                key
                for key, values in daily.items()
                if values.get("T2M") is not None
                and values.get("PRECTOTCORR") is not None
            )
            if not valid_dates:
                continue
            observation_date = valid_dates[-1]
            values = daily[observation_date]
            return WeatherSnapshot(
                temperature_c=float(values["T2M"]),
                rainfall_mm=float(values["PRECTOTCORR"]),
                humidity_percent=values["RH2M"],
                month=month,
                period_start=observation_date[:4]
                + "-"
                + observation_date[4:6]
                + "-"
                + observation_date[6:],
                period_end=observation_date[:4]
                + "-"
                + observation_date[4:6]
                + "-"
                + observation_date[6:],
                days_averaged=1,
            )
    except WeatherServiceError:
        raise
    finally:
        if owns_client:
            await client.aclose()

    raise WeatherServiceError(
        "NASA POWER returned no usable temperature and rainfall data in the "
        "last 180 days."
    )


async def fetch_daily_weather(
    latitude: float,
    longitude: float,
    period_start: date,
    period_end: date,
    client: httpx.AsyncClient,
) -> dict[str, dict[str, float | None]]:
    """Fetch daily values keyed by YYYYMMDD for one point and date interval."""
    if period_start > period_end:
        raise ValueError("Weather period start must not be after its end.")
    parameters = {
        "parameters": ",".join(WEATHER_PARAMETERS),
        "community": "AG",
        "longitude": str(longitude),
        "latitude": str(latitude),
        "start": period_start.strftime("%Y%m%d"),
        "end": period_end.strftime("%Y%m%d"),
        "format": "JSON",
    }
    try:
        response = await client.get(NASA_POWER_URL, params=parameters)
        response.raise_for_status()
    except httpx.HTTPError as exc:
        raise WeatherServiceError(
            f"NASA POWER request failed for {latitude}, {longitude}: {exc}"
        ) from exc

    try:
        payload = response.json()
    except ValueError as exc:
        raise WeatherServiceError("NASA POWER returned invalid JSON.") from exc

    properties = payload.get("properties") if isinstance(payload, dict) else None
    parameter_data = (
        properties.get("parameter") if isinstance(properties, dict) else None
    )
    if not isinstance(parameter_data, dict):
        raise WeatherServiceError("NASA POWER response has no parameter data.")

    raw_parameters = {
        name: parameter_data.get(name)
        for name in WEATHER_PARAMETERS
    }
    if not isinstance(raw_parameters["T2M"], dict) or not isinstance(
        raw_parameters["PRECTOTCORR"], dict
    ):
        raise WeatherServiceError(
            "NASA POWER response is missing temperature or rainfall."
        )

    keys = set(raw_parameters["T2M"]) | set(raw_parameters["PRECTOTCORR"])
    if isinstance(raw_parameters["RH2M"], dict):
        keys.update(raw_parameters["RH2M"])
    start_key = period_start.strftime("%Y%m%d")
    end_key = period_end.strftime("%Y%m%d")
    daily: dict[str, dict[str, float | None]] = {}
    for key in keys:
        if (
            not isinstance(key, str)
            or len(key) != 8
            or not key.isdigit()
            or key < start_key
            or key > end_key
        ):
            continue
        daily[key] = {
            name: _valid_value(
                raw_parameters[name].get(key)
                if isinstance(raw_parameters[name], dict)
                else None
            )
            for name in WEATHER_PARAMETERS
        }
    return daily


def _valid_value(raw_value: Any) -> float | None:
    try:
        value = float(raw_value)
    except (TypeError, ValueError):
        return None
    if not math.isfinite(value) or value <= -900:
        return None
    return value
