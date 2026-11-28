from __future__ import annotations

import io
import logging
from typing import Literal

from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, ConfigDict, Field

from app.plant_support import (
    HEALTH_LABEL_PREFIX_BY_PLANT_NAME,
    health_label_prefix_for,
    normalize_plant_name,
    normalize_species_label,
)


logger = logging.getLogger(__name__)
router = APIRouter()

MODEL_ID = "linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification"
DISCLAIMER = (
    "This is an AI estimate, not a replacement for an expert diagnosis."
)
PHOTO_MISMATCH_MESSAGE = (
    "Photo does not look like selected plant, please retake image"
)
LOW_CONFIDENCE_MESSAGE = "Not sure, please retake photo in good light"
MAX_IMAGE_BYTES = 10 * 1024 * 1024
MIN_CONFIDENCE = 0.6


class PlantHealthResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: Literal["healthy", "disease", "retake"]
    label: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    treatment_tips: list[str] = Field(default_factory=list)
    message: str | None = None
    disclaimer: str = DISCLAIMER


class InvalidPlantImage(ValueError):
    pass


class PlantHealthAnalyzer:
    def __init__(
        self,
        *,
        processor: object,
        model: object,
        torch_module: object,
        id2label: dict[int, str],
    ) -> None:
        self._processor = processor
        self._model = model
        self._torch = torch_module
        self._id2label = id2label
        self._device = torch_module.device(
            "cuda" if torch_module.cuda.is_available() else "cpu"
        )
        model.to(self._device)
        model.eval()
        self._validate_model_species()

    @classmethod
    def load(
        cls,
        model_id: str = MODEL_ID,
    ) -> PlantHealthAnalyzer:
        try:
            import torch
            from transformers import (
                AutoModelForImageClassification,
                MobileNetV2ImageProcessor,
            )

            processor = MobileNetV2ImageProcessor.from_pretrained(model_id)
            model = AutoModelForImageClassification.from_pretrained(model_id)
            raw_labels = model.config.id2label
            id2label = {
                int(index): label for index, label in raw_labels.items()
            }
            logger.info(
                "Loaded plant-health model %s with id2label: %s",
                model_id,
                id2label,
            )
            return cls(
                processor=processor,
                model=model,
                torch_module=torch,
                id2label=id2label,
            )
        except Exception as error:
            logger.exception(
                "Failed to load plant-health model %s.", model_id
            )
            raise RuntimeError(
                f"Unable to load plant-health model {model_id}."
            ) from error

    def _validate_model_species(self) -> None:
        available = {
            normalize_species_label(label) for label in self._id2label.values()
        }
        required = {
            normalize_species_label(prefix)
            for prefix in HEALTH_LABEL_PREFIX_BY_PLANT_NAME.values()
        }
        missing = required - available
        if missing:
            raise RuntimeError(
                "Plant-health model is missing supported species labels."
            )

    def analyze(self, image_bytes: bytes, plant_name: str) -> PlantHealthResponse:
        prefix = health_label_prefix_for(plant_name)
        if prefix is None:
            raise ValueError("Plant health analysis is not supported for this plant.")

        try:
            from PIL import Image, UnidentifiedImageError

            with Image.open(io.BytesIO(image_bytes)) as source_image:
                image = source_image.convert("RGB")
        except (UnidentifiedImageError, OSError, ValueError) as error:
            raise InvalidPlantImage("Upload a valid plant photo.") from error

        inputs = self._processor(images=image, return_tensors="pt")
        pixel_values = inputs["pixel_values"].to(self._device)
        with self._torch.inference_mode():
            logits = self._model(pixel_values=pixel_values).logits[0]
            probabilities = self._torch.softmax(logits, dim=-1).cpu().tolist()

        raw_top_ten = sorted(
            enumerate(probabilities),
            key=lambda item: item[1],
            reverse=True,
        )[:10]
        logger.info(
            "Plant-health raw top-10 softmax predictions before species "
            "filtering: %s",
            [
                (index, self._id2label[index], probability)
                for index, probability in raw_top_ten
            ],
        )

        return self.interpret_predictions(
            plant_name=plant_name,
            labels=self._id2label,
            probabilities=probabilities,
        )

    @staticmethod
    def interpret_predictions(
        *,
        plant_name: str,
        labels: dict[int, str],
        probabilities: list[float],
    ) -> PlantHealthResponse:
        prefix = health_label_prefix_for(plant_name)
        if prefix is None:
            raise ValueError("Plant health analysis is not supported for this plant.")
        if set(labels) != set(range(len(probabilities))):
            raise ValueError("Model returned a mismatched label count.")

        predictions = sorted(
            (
                (labels[index], float(probability))
                for index, probability in enumerate(probabilities)
                if index in labels
            ),
            key=lambda item: item[1],
            reverse=True,
        )
        if not predictions:
            raise ValueError("Plant-health model returned no predictions.")

        target_species = normalize_species_label(prefix)
        best_label, best_confidence = predictions[0]
        if best_confidence < MIN_CONFIDENCE:
            return PlantHealthResponse(
                status="retake",
                confidence=best_confidence,
                message=LOW_CONFIDENCE_MESSAGE,
            )
        if normalize_species_label(best_label) != target_species:
            return PlantHealthResponse(
                status="retake",
                message=PHOTO_MISMATCH_MESSAGE,
            )

        matching = [
            prediction
            for prediction in predictions
            if normalize_species_label(prediction[0]) == target_species
        ]
        label, confidence = matching[0]

        class_name = label.split("___", maxsplit=1)[-1]
        is_healthy = (
            class_name.casefold() == "healthy"
            or class_name.casefold().startswith("healthy ")
        )
        display_label = (
            "Healthy"
            if is_healthy
            else " ".join(
                class_name.replace("_", " ").replace(",", " ").split()
            ).title()
        )
        tips = (
            ["Continue the current care routine and monitor new growth."]
            if is_healthy
            else [
                "Remove badly affected foliage and avoid wetting leaves.",
                "Improve airflow around the plant and ask a local plant-health "
                "expert about treatment options.",
            ]
        )
        return PlantHealthResponse(
            status="healthy" if is_healthy else "disease",
            label=display_label,
            confidence=confidence,
            treatment_tips=tips,
        )


@router.post(
    "/health-analysis",
    response_model=PlantHealthResponse,
    summary="Analyze a supported plant photo with the pretrained classifier",
)
async def analyze_plant_health(
    request: Request,
    image: UploadFile = File(...),
    plant_name: str = Form(...),
) -> PlantHealthResponse:
    if normalize_plant_name(plant_name) not in HEALTH_LABEL_PREFIX_BY_PLANT_NAME:
        return PlantHealthResponse(
            status="retake",
            message="Plant health analysis is not supported for this plant.",
        )

    image_bytes = await image.read(MAX_IMAGE_BYTES + 1)
    if not image_bytes:
        raise HTTPException(status_code=422, detail="Upload a plant photo.")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=413,
            detail="Plant photos must be 10 MB or smaller.",
        )

    analyzer: PlantHealthAnalyzer = request.app.state.plant_health_analyzer
    try:
        return await run_in_threadpool(
            analyzer.analyze,
            image_bytes,
            plant_name,
        )
    except InvalidPlantImage as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except Exception as error:
        logger.exception("Plant health analysis failed.")
        raise HTTPException(
            status_code=500,
            detail="Plant health analysis is temporarily unavailable.",
        ) from error
