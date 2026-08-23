# TheobroTect offline map

The bundled map is generated from raw OpenStreetMap features and is licensed
under the ODbL. The generator does not download rendered tiles from
`tile.openstreetmap.org`, whose usage policy prohibits offline tile archives.

From the repository root, with Python 3, Pillow, and Requests installed:

```powershell
python tool/offline_map/generate_tiles.py
```

The script queries the supported area's buffered bounding box, renders a small
mobile-friendly raster style, and writes polygon-clipped 256×256 WebP assets for
zooms 12–17. Its raw-data response is cached under `tool/offline_map/cache/` to
make renderer iteration reproducible without repeatedly querying Overpass.

After regenerating, review `assets/maps/offline/metadata.json`, inspect sample
tiles at zooms 12, 15, and 17, run the Flutter tests, and test a release build in
airplane mode before distribution.
