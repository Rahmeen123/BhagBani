from __future__ import annotations

import argparse
import csv
import io
from pathlib import Path

from app.plant_support import (
    HEALTH_LABEL_PREFIX_BY_PLANT_NAME,
    normalize_plant_name,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = PROJECT_ROOT / "dataset for plant recommendation" / "plants.csv"
DEFAULT_OUTPUT = (
    PROJECT_ROOT / "dataset for plant recommendation" / "plants_clean.csv"
)

SOURCE_COLUMNS = (
    "Plant Name",
    "Growth",
    "Soil",
    "Sunlight",
    "Watering",
    "Fertilization Type",
)
OUTPUT_COLUMNS = (
    "name",
    "growth",
    "soil",
    "sunlight",
    "care_level",
    "watering_text",
    "fertilization",
    "health_supported",
    "health_label_prefix",
)
CARE_LEVEL_BY_WATERING = {
    "water when soil is dry": "Low",
    "let soil dry between watering": "Low",
    "water when topsoil is dry": "Low",
    "water when soil feels dry": "Low",
    "water weekly": "Regular",
    "regular watering": "Regular",
    "regular, well-drained soil": "Regular",
    "keep soil slightly moist": "Regular",
    "keep soil moist": "High",
    "keep soil consistently moist": "High",
    "keep soil evenly moist": "High",
    "regular, moist soil": "High",
}
WINDOWS_1252_SPECIAL_BYTES = {
    0x80: "€",
    0x85: "…",
    0x91: "‘",
    0x92: "’",
    0x93: "“",
    0x94: "”",
    0x95: "•",
    0x96: "–",
    0x97: "—",
    0x99: "™",
}


def decode_cp1252_csv(data: bytes) -> str:
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]

    decoded: list[str] = []
    index = 0
    while index < len(data):
        byte = data[index]
        if byte < 0x80:
            decoded.append(chr(byte))
            index += 1
            continue

        sequence_length = (
            2
            if byte & 0xE0 == 0xC0
            else 3
            if byte & 0xF0 == 0xE0
            else 4
            if byte & 0xF8 == 0xF0
            else 1
        )
        if sequence_length > 1 and index + sequence_length <= len(data):
            try:
                decoded.append(data[index : index + sequence_length].decode("utf-8"))
                index += sequence_length
                continue
            except UnicodeDecodeError:
                pass

        decoded.append(
            WINDOWS_1252_SPECIAL_BYTES.get(
                byte, bytes([byte]).decode("cp1252", errors="replace")
            )
        )
        index += 1
    return "".join(decoded)


def clean_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    cleaned: list[dict[str, str]] = []
    seen_names: set[str] = set()

    for row_number, row in enumerate(rows, start=2):
        missing_columns = [column for column in SOURCE_COLUMNS if column not in row]
        if missing_columns:
            raise ValueError(
                f"Plant dataset is missing columns: {', '.join(missing_columns)}"
            )

        name = row["Plant Name"].strip()
        if not name:
            raise ValueError(f"Plant name is empty on dataset row {row_number}.")
        normalized_name = normalize_plant_name(name)
        if normalized_name in seen_names:
            continue

        watering_text = row["Watering"].strip()
        care_level = CARE_LEVEL_BY_WATERING.get(watering_text.casefold())
        if care_level is None:
            raise ValueError(
                f"Unknown watering instruction for {name!r}: {watering_text!r}"
            )

        prefix = HEALTH_LABEL_PREFIX_BY_PLANT_NAME.get(normalized_name, "")
        cleaned.append(
            {
                "name": name,
                "growth": row["Growth"].strip().casefold(),
                "soil": row["Soil"].strip().casefold(),
                "sunlight": row["Sunlight"].strip().casefold(),
                "care_level": care_level,
                "watering_text": watering_text,
                "fertilization": row["Fertilization Type"].strip(),
                "health_supported": str(bool(prefix)).lower(),
                "health_label_prefix": prefix,
            }
        )
        seen_names.add(normalized_name)

    return cleaned


def clean_dataset(source: Path, destination: Path) -> int:
    with source.open("rb") as csv_file:
        content = decode_cp1252_csv(csv_file.read())
    rows = list(csv.DictReader(io.StringIO(content, newline="")))
    cleaned = clean_rows(rows)

    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=OUTPUT_COLUMNS)
        writer.writeheader()
        writer.writerows(cleaned)
    return len(cleaned)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Clean the Garden plant recommendation CSV."
    )
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    arguments = parser.parse_args()

    count = clean_dataset(arguments.source, arguments.output)
    print(f"Wrote {count} unique plants to {arguments.output}")


if __name__ == "__main__":
    main()
