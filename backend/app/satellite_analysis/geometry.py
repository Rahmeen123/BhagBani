"""GeoJSON polygon validation and geodesic area estimation."""

from __future__ import annotations

import math
from typing import Any


EARTH_RADIUS_METERS = 6_371_008.8
MAX_COORDINATES = 2_000


class PolygonValidationError(ValueError):
    """Raised when a GeoJSON polygon is malformed or outside area limits."""


def validate_polygon(geometry: dict[str, Any]) -> float:
    """Validate a GeoJSON Polygon and return its area in hectares."""
    if geometry.get("type") != "Polygon":
        raise PolygonValidationError("Geometry must be a GeoJSON Polygon.")
    coordinates = geometry.get("coordinates")
    if not isinstance(coordinates, list) or not coordinates:
        raise PolygonValidationError("Polygon coordinates are required.")
    if (
        sum(len(ring) for ring in coordinates if isinstance(ring, list))
        > MAX_COORDINATES
    ):
        raise PolygonValidationError("Polygon has too many coordinates.")

    rings: list[list[tuple[float, float]]] = []
    for ring in coordinates:
        if not isinstance(ring, list) or len(ring) < 4:
            raise PolygonValidationError("Each polygon ring needs at least four positions.")
        points: list[tuple[float, float]] = []
        for position in ring:
            if (
                not isinstance(position, (list, tuple))
                or len(position) not in (2, 3)
                or not all(_is_number(value) for value in position)
            ):
                raise PolygonValidationError(
                    "Polygon positions must contain longitude and latitude."
                )
            longitude, latitude = float(position[0]), float(position[1])
            if not -180 <= longitude <= 180 or not -90 <= latitude <= 90:
                raise PolygonValidationError("Polygon coordinates are outside valid ranges.")
            points.append((longitude, latitude))
        if points[0] != points[-1]:
            raise PolygonValidationError("Polygon rings must be closed.")
        if (
            len(set(points[:-1])) < 3
            or any(points[index] == points[index + 1] for index in range(len(points) - 1))
            or _has_self_intersection(points)
        ):
            raise PolygonValidationError(
                "Polygon rings must form valid, non-intersecting boundaries."
            )
        if any(
            abs(points[index][0] - points[index - 1][0]) > 180
            for index in range(1, len(points))
        ):
            raise PolygonValidationError(
                "Polygons crossing the antimeridian are not supported."
            )
        rings.append(points)

    outer_area = _ring_area(rings[0])
    hole_areas = sum(_ring_area(ring) for ring in rings[1:])
    if any(
        _rings_intersect(rings[0], ring) or not _point_in_ring(ring[0], rings[0])
        for ring in rings[1:]
    ):
        raise PolygonValidationError("Polygon holes must lie inside the exterior boundary.")
    for index, ring in enumerate(rings[1:]):
        for other_ring in rings[index + 2 :]:
            if (
                _rings_intersect(ring, other_ring)
                or _point_in_ring(ring[0], other_ring)
                or _point_in_ring(other_ring[0], ring)
            ):
                raise PolygonValidationError("Polygon holes must not overlap.")
    area_hectares = (outer_area - hole_areas) / 10_000
    if area_hectares <= 0:
        raise PolygonValidationError("Polygon area must be greater than zero.")
    return area_hectares


def _is_number(value: object) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
    )


def _ring_area(ring: list[tuple[float, float]]) -> float:
    total = 0.0
    for index in range(len(ring) - 1):
        lon1, lat1 = map(math.radians, ring[index])
        lon2, lat2 = map(math.radians, ring[index + 1])
        total += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2))
    return abs(total * EARTH_RADIUS_METERS**2 / 2)


def _has_self_intersection(ring: list[tuple[float, float]]) -> bool:
    edges = list(zip(ring[:-1], ring[1:]))
    for first_index, (a, b) in enumerate(edges):
        for second_index, (c, d) in enumerate(edges[first_index + 1 :], first_index + 1):
            if second_index in (first_index, first_index + 1):
                continue
            if first_index == 0 and second_index == len(edges) - 1:
                continue
            if _segments_intersect(a, b, c, d):
                return True
    return False


def _segments_intersect(
    a: tuple[float, float],
    b: tuple[float, float],
    c: tuple[float, float],
    d: tuple[float, float],
) -> bool:
    def orientation(p: tuple[float, float], q: tuple[float, float], r: tuple[float, float]) -> float:
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])

    first = orientation(a, b, c)
    second = orientation(a, b, d)
    third = orientation(c, d, a)
    fourth = orientation(c, d, b)
    if first * second < 0 and third * fourth < 0:
        return True
    epsilon = 1e-12

    def on_segment(
        start: tuple[float, float],
        point: tuple[float, float],
        end: tuple[float, float],
    ) -> bool:
        return (
            min(start[0], end[0]) - epsilon <= point[0] <= max(start[0], end[0]) + epsilon
            and min(start[1], end[1]) - epsilon <= point[1] <= max(start[1], end[1]) + epsilon
        )

    return (
        abs(first) <= epsilon and on_segment(a, c, b)
        or abs(second) <= epsilon and on_segment(a, d, b)
        or abs(third) <= epsilon and on_segment(c, a, d)
        or abs(fourth) <= epsilon and on_segment(c, b, d)
    )


def _rings_intersect(
    first: list[tuple[float, float]], second: list[tuple[float, float]]
) -> bool:
    return any(
        _segments_intersect(start_a, end_a, start_b, end_b)
        for start_a, end_a in zip(first[:-1], first[1:])
        for start_b, end_b in zip(second[:-1], second[1:])
    )


def _point_in_ring(point: tuple[float, float], ring: list[tuple[float, float]]) -> bool:
    longitude, latitude = point
    inside = False
    for index in range(len(ring) - 1):
        x1, y1 = ring[index]
        x2, y2 = ring[index + 1]
        if (y1 > latitude) != (y2 > latitude):
            crossing_longitude = (x2 - x1) * (latitude - y1) / (y2 - y1) + x1
            if longitude < crossing_longitude:
                inside = not inside
    return inside
