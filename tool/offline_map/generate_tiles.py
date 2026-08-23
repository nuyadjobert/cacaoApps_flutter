#!/usr/bin/env python3
"""Generate the bundled raster tile pyramid from raw OpenStreetMap data.

This intentionally reads OSM features from an Overpass API endpoint. It never
downloads or scrapes rendered tiles from tile.openstreetmap.org.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import requests
from PIL import Image, ImageDraw, ImageFont


BOUNDARY = [
    (7.806560861082189, 125.63986102045375),
    (7.7956762095560865, 125.63196459707926),
    (7.794995909431882, 125.66320696782175),
    (7.741929100320352, 125.64020434320918),
    (7.743630063488939, 125.68655291518975),
    (7.722537635330425, 125.67693987803823),
    (7.68608165649672, 125.68385925522492),
    (7.671187109483628, 125.70077199774289),
    (7.680133924592561, 125.7221384442543),
    (7.66464738677233, 125.72361706165712),
    (7.6526771983407205, 125.74031302153712),
    (7.652043473116281, 125.7484123382937),
    (7.683939805531676, 125.76134282642398),
    (7.682813265212966, 125.77782564636436),
    (7.691332653669563, 125.78493031018593),
    (7.7033721590568724, 125.77945971904207),
    (7.70808359287765, 125.77164314928795),
    (7.727444436605209, 125.76759349090968),
    (7.741435502048624, 125.75246835983998),
    (7.752139988193796, 125.73589958976596),
    (7.763325284000295, 125.72782762483625),
    (7.811671196718009, 125.72624964672997),
    (7.827604881331258, 125.70919534486183),
    (7.823215663004752, 125.70694976062417),
    (7.830551043241702, 125.69462939311539),
    (7.842360795049566, 125.66801254185408),
    (7.823328174293252, 125.63906132053842),
    (7.808920959985727, 125.64199646739989),
]

TILE_SIZE = 256
SCALE = 2
MIN_ZOOM = 12
MAX_ZOOM = 17
TILE_BUFFER = 2


@dataclass(frozen=True)
class Feature:
    geometry: tuple[tuple[float, float], ...]
    tags: dict[str, str]


def tile_x(longitude: float, zoom: int) -> float:
    return (longitude + 180.0) / 360.0 * (2**zoom)


def tile_y(latitude: float, zoom: int) -> float:
    latitude_radians = math.radians(latitude)
    return (
        1.0 - math.asinh(math.tan(latitude_radians)) / math.pi
    ) / 2.0 * (2**zoom)


def point_in_polygon(
    x: float,
    y: float,
    polygon: tuple[tuple[float, float], ...],
) -> bool:
    inside = False
    previous = len(polygon) - 1
    for current in range(len(polygon)):
        current_x, current_y = polygon[current]
        previous_x, previous_y = polygon[previous]
        crosses = (current_y > y) != (previous_y > y)
        if crosses:
            intersection_x = (
                (previous_x - current_x)
                * (y - current_y)
                / (previous_y - current_y)
                + current_x
            )
            if x < intersection_x:
                inside = not inside
        previous = current
    return inside


def selected_tiles(zoom: int) -> set[tuple[int, int]]:
    polygon = tuple((tile_x(lon, zoom), tile_y(lat, zoom)) for lat, lon in BOUNDARY)
    min_x = math.floor(min(point[0] for point in polygon))
    max_x = math.floor(max(point[0] for point in polygon))
    min_y = math.floor(min(point[1] for point in polygon))
    max_y = math.floor(max(point[1] for point in polygon))

    core: set[tuple[int, int]] = set()
    for x in range(min_x, max_x + 1):
        for y in range(min_y, max_y + 1):
            samples = (
                (x + sample_x / 4.0, y + sample_y / 4.0)
                for sample_x in range(5)
                for sample_y in range(5)
            )
            contains_sample = any(
                point_in_polygon(sample_x, sample_y, polygon)
                for sample_x, sample_y in samples
            )
            contains_vertex = any(
                math.floor(vertex_x) == x and math.floor(vertex_y) == y
                for vertex_x, vertex_y in polygon
            )
            if contains_sample or contains_vertex:
                core.add((x, y))

    return {
        (x + offset_x, y + offset_y)
        for x, y in core
        for offset_x in range(-TILE_BUFFER, TILE_BUFFER + 1)
        for offset_y in range(-TILE_BUFFER, TILE_BUFFER + 1)
    }


def build_query() -> str:
    south = min(point[0] for point in BOUNDARY) - 0.015
    west = min(point[1] for point in BOUNDARY) - 0.015
    north = max(point[0] for point in BOUNDARY) + 0.015
    east = max(point[1] for point in BOUNDARY) + 0.015
    bbox = f"{south},{west},{north},{east}"
    selectors = [
        "highway",
        "waterway",
        "building",
        "landuse",
        "natural",
        "water",
        "leisure=park",
    ]
    way_queries = "\n".join(
        f'way["{selector.split("=")[0]}"'
        + (
            f'="{selector.split("=")[1]}"]({bbox});'
            if "=" in selector
            else f"]({bbox});"
        )
        for selector in selectors
    )
    return f"""[out:json][timeout:600][maxsize:1073741824];
(
{way_queries}
node["place"]({bbox});
);
out geom;
"""


def download_osm(endpoint: str, cache_path: Path) -> dict[str, object]:
    if cache_path.exists():
        print(f"Using cached OSM response: {cache_path}")
        return json.loads(cache_path.read_text(encoding="utf-8"))

    print(f"Downloading raw OSM features from {endpoint}")
    response = requests.post(
        endpoint,
        data={"data": build_query()},
        headers={"User-Agent": "TheobroTect-offline-map-builder/1.0"},
        timeout=660,
    )
    response.raise_for_status()
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_bytes(response.content)
    return response.json()


def parse_features(payload: dict[str, object]) -> tuple[list[Feature], list[Feature]]:
    ways: list[Feature] = []
    places: list[Feature] = []
    elements = payload.get("elements")
    if not isinstance(elements, list):
        raise ValueError("Overpass response has no elements list")

    for element in elements:
        if not isinstance(element, dict):
            continue
        raw_tags = element.get("tags", {})
        if not isinstance(raw_tags, dict):
            continue
        tags = {str(key): str(value) for key, value in raw_tags.items()}
        if element.get("type") == "node" and "lat" in element and "lon" in element:
            places.append(
                Feature(
                    geometry=((float(element["lat"]), float(element["lon"])),),
                    tags=tags,
                )
            )
            continue

        geometry = element.get("geometry")
        if not isinstance(geometry, list):
            continue
        points = tuple(
            (float(point["lat"]), float(point["lon"]))
            for point in geometry
            if isinstance(point, dict) and "lat" in point and "lon" in point
        )
        if len(points) >= 2:
            ways.append(Feature(geometry=points, tags=tags))

    return ways, places


def polygon_style(tags: dict[str, str]) -> tuple[str, str] | None:
    natural = tags.get("natural")
    landuse = tags.get("landuse")
    if natural in {"water", "bay"} or "water" in tags:
        return "#b9d9eb", "#99c5dd"
    if natural in {"wood", "scrub"} or landuse in {"forest", "orchard"}:
        return "#d4e5cc", "#bfd7b5"
    if landuse in {"farmland", "farmyard", "meadow"}:
        return "#eee8c9", "#ddd5ae"
    if landuse in {"residential", "commercial", "industrial"}:
        return "#e8e3df", "#d7d0ca"
    if tags.get("leisure") == "park" or landuse in {"grass", "recreation_ground"}:
        return "#dcebcf", "#c8dfb7"
    if "building" in tags:
        return "#ded4ce", "#c4b8b0"
    return None


def road_style(highway: str) -> tuple[int, str, int, str]:
    if highway in {"motorway", "trunk"}:
        return 8, "#c88d58", 5, "#f5b878"
    if highway == "primary":
        return 7, "#cf9b62", 4, "#f2c78d"
    if highway == "secondary":
        return 6, "#c7a875", 4, "#f3dcaa"
    if highway == "tertiary":
        return 5, "#b7afa2", 3, "#fff7df"
    if highway in {"residential", "unclassified"}:
        return 4, "#c4beb5", 2, "#ffffff"
    if highway in {"service", "track"}:
        return 3, "#c9c1b5", 1, "#f7f2e9"
    return 2, "#aaa59e", 1, "#eeeae4"


def project_geometry(
    geometry: Iterable[tuple[float, float]],
    zoom: int,
    tile: tuple[int, int],
) -> list[tuple[float, float]]:
    tile_origin_x, tile_origin_y = tile
    return [
        (
            (tile_x(longitude, zoom) - tile_origin_x) * TILE_SIZE * SCALE,
            (tile_y(latitude, zoom) - tile_origin_y) * TILE_SIZE * SCALE,
        )
        for latitude, longitude in geometry
    ]


def feature_tiles(
    feature: Feature,
    zoom: int,
    allowed: set[tuple[int, int]],
) -> Iterable[tuple[int, int]]:
    projected = [
        (tile_x(longitude, zoom), tile_y(latitude, zoom))
        for latitude, longitude in feature.geometry
    ]
    min_x = math.floor(min(point[0] for point in projected))
    max_x = math.floor(max(point[0] for point in projected))
    min_y = math.floor(min(point[1] for point in projected))
    max_y = math.floor(max(point[1] for point in projected))
    for x in range(min_x, max_x + 1):
        for y in range(min_y, max_y + 1):
            if (x, y) in allowed:
                yield x, y


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size * SCALE)
    except OSError:
        return ImageFont.load_default(size=size * SCALE)


def render_tiles(
    ways: list[Feature],
    places: list[Feature],
    output_dir: Path,
) -> dict[int, int]:
    output_dir.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (1, 1), (0, 0, 0, 0)).save(
        output_dir / "transparent.png"
    )

    counts: dict[int, int] = {}
    for zoom in range(MIN_ZOOM, MAX_ZOOM + 1):
        allowed = selected_tiles(zoom)
        counts[zoom] = len(allowed)
        index: dict[tuple[int, int], list[Feature]] = defaultdict(list)
        place_index: dict[tuple[int, int], list[Feature]] = defaultdict(list)

        for feature in ways:
            if zoom < 15 and "building" in feature.tags:
                continue
            for tile in feature_tiles(feature, zoom, allowed):
                index[tile].append(feature)
        for place in places:
            for tile in feature_tiles(place, zoom, allowed):
                place_index[tile].append(place)

        print(f"Rendering zoom {zoom}: {len(allowed)} tiles")
        for tile_number, tile in enumerate(sorted(allowed), start=1):
            image = Image.new(
                "RGB",
                (TILE_SIZE * SCALE, TILE_SIZE * SCALE),
                "#f3f0e8",
            )
            draw = ImageDraw.Draw(image)
            features = index.get(tile, [])

            for feature in features:
                style = polygon_style(feature.tags)
                if style is None or feature.geometry[0] != feature.geometry[-1]:
                    continue
                fill, outline = style
                points = project_geometry(feature.geometry, zoom, tile)
                draw.polygon(points, fill=fill, outline=outline, width=SCALE)

            for feature in features:
                if "waterway" not in feature.tags:
                    continue
                points = project_geometry(feature.geometry, zoom, tile)
                draw.line(points, fill="#78b6d6", width=max(SCALE, (zoom - 12) * SCALE))

            road_features = [feature for feature in features if "highway" in feature.tags]
            road_features.sort(
                key=lambda feature: road_style(feature.tags["highway"])[0]
            )
            for feature in road_features:
                casing_width, casing, inner_width, inner = road_style(
                    feature.tags["highway"]
                )
                points = project_geometry(feature.geometry, zoom, tile)
                draw.line(
                    points,
                    fill=casing,
                    width=casing_width * SCALE,
                    joint="curve",
                )
                draw.line(
                    points,
                    fill=inner,
                    width=inner_width * SCALE,
                    joint="curve",
                )

            if zoom >= 15:
                label_font = font(9 if zoom == 15 else 10)
                labeled: set[str] = set()
                for feature in road_features:
                    name = feature.tags.get("name")
                    if not name or name in labeled:
                        continue
                    points = project_geometry(feature.geometry, zoom, tile)
                    center_x, center_y = points[len(points) // 2]
                    if 12 <= center_x <= TILE_SIZE * SCALE - 12 and 12 <= center_y <= TILE_SIZE * SCALE - 12:
                        draw.text(
                            (center_x, center_y),
                            name,
                            font=label_font,
                            fill="#645f58",
                            stroke_width=2,
                            stroke_fill="#ffffff",
                            anchor="mm",
                        )
                        labeled.add(name)

            place_font = font(10 if zoom <= 14 else 11)
            for place in place_index.get(tile, []):
                name = place.tags.get("name")
                if not name:
                    continue
                center_x, center_y = project_geometry(place.geometry, zoom, tile)[0]
                draw.ellipse(
                    (
                        center_x - 2 * SCALE,
                        center_y - 2 * SCALE,
                        center_x + 2 * SCALE,
                        center_y + 2 * SCALE,
                    ),
                    fill="#5f5a52",
                )
                draw.text(
                    (center_x + 4 * SCALE, center_y),
                    name,
                    font=place_font,
                    fill="#45413c",
                    stroke_width=2,
                    stroke_fill="#ffffff",
                    anchor="lm",
                )

            image = image.resize(
                (TILE_SIZE, TILE_SIZE),
                resample=Image.Resampling.LANCZOS,
            )
            x, y = tile
            image.save(
                output_dir / f"{zoom}_{x}_{y}.webp",
                "WEBP",
                quality=82,
                method=4,
            )
            if tile_number % 500 == 0:
                print(f"  {tile_number}/{len(allowed)}")

    return counts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--endpoint",
        default="https://overpass-api.de/api/interpreter",
    )
    parser.add_argument(
        "--cache",
        type=Path,
        default=Path("tool/offline_map/cache/osm-features.json"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/maps/offline"),
    )
    args = parser.parse_args()

    payload = download_osm(args.endpoint, args.cache)
    ways, places = parse_features(payload)
    print(f"Parsed {len(ways)} ways and {len(places)} named places")
    counts = render_tiles(ways, places, args.output)

    metadata = {
        "source": args.endpoint,
        "source_type": "OpenStreetMap raw data via Overpass API",
        "license": "ODbL 1.0",
        "license_url": "https://www.openstreetmap.org/copyright",
        "min_zoom": MIN_ZOOM,
        "max_zoom": MAX_ZOOM,
        "tile_buffer": TILE_BUFFER,
        "tile_format": "WebP 256x256 quality 82",
        "tile_counts": counts,
        "feature_counts": {"ways": len(ways), "places": len(places)},
        "overpass_osm3s": payload.get("osm3s", {}),
    }
    (args.output / "metadata.json").write_text(
        json.dumps(metadata, indent=2),
        encoding="utf-8",
    )
    print(f"Generated {sum(counts.values())} tiles in {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
