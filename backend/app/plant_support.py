from __future__ import annotations

import re


HEALTH_LABEL_PREFIX_BY_PLANT_NAME = {
    "tomato": "Tomato___",
    "apple tree": "Apple___",
    "corn": "Corn_(maize)___",
    "corn / zea mays": "Corn_(maize)___",
    "zea mays": "Corn_(maize)___",
    "zea mays (corn)": "Corn_(maize)___",
    "grape vine": "Grape___",
    "strawberry": "Strawberry___",
    "strawberry plant": "Strawberry___",
    "pepper plant": "Pepper,_bell___",
    "acorn squash": "Squash___",
    "butternut squash": "Squash___",
    "raspberry": "Raspberry___",
}


def normalize_plant_name(name: str) -> str:
    return " ".join(name.strip().casefold().split())


def normalize_species_label(label: str) -> str:
    species_name = label.split("___", maxsplit=1)[0].casefold()
    normalized = re.sub(r"[^a-z0-9]+", "", species_name)
    for species in (
        "tomato",
        "apple",
        "grape",
        "strawberry",
        "squash",
        "raspberry",
    ):
        if species in normalized:
            return species
    if "corn" in normalized:
        return "cornmaize"
    if "pepper" in normalized:
        return "pepperbell"
    return normalized


def health_label_prefix_for(name: str) -> str | None:
    return HEALTH_LABEL_PREFIX_BY_PLANT_NAME.get(normalize_plant_name(name))
