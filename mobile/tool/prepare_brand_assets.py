#!/usr/bin/env python3
"""Prepare reproducible Kargozar Android/store icon assets from the approved logo."""
from pathlib import Path
from PIL import Image, ImageOps
import shutil
import sys

if len(sys.argv) != 3:
    raise SystemExit("Usage: prepare_brand_assets.py SOURCE_IMAGE OUTPUT_DIRECTORY")

source = Path(sys.argv[1])
output = Path(sys.argv[2])
if not source.is_file():
    raise SystemExit(f"Logo source not found: {source}")

output.mkdir(parents=True, exist_ok=True)
logo = Image.open(source).convert("RGB")

def store_icon(size: int) -> Image.Image:
    canvas = Image.new("RGB", (size, size), (255, 255, 255))
    margin = 24 if size >= 512 else 12
    artwork = ImageOps.contain(
        logo, (size - margin, size - margin), method=Image.Resampling.LANCZOS
    )
    canvas.paste(artwork, ((size - artwork.width) // 2, (size - artwork.height) // 2))
    return canvas

# Opaque, square store listing artwork and high-resolution master.
store_icon(512).save(output / "myket-store-icon-512.png", "PNG", optimize=True)
store_icon(1024).save(output / "app-icon-master-1024.png", "PNG", optimize=True)

# Android adaptive foreground: emblem only, transparent outside the artwork.
# Crop excludes the decorative card border and keeps the purple/red mark and swoosh.
emblem = logo.crop((42, 40, 214, 171)).convert("RGBA")
pixels = emblem.load()
for y in range(emblem.height):
    for x in range(emblem.width):
        r, g, b, _ = pixels[x, y]
        maximum = max(r, g, b)
        saturation = (maximum - min(r, g, b)) / max(maximum, 1)
        alpha = max(0, min(255, round(saturation * 255)))
        pixels[x, y] = (r, g, b, alpha) if alpha >= 16 else (0, 0, 0, 0)

bounds = emblem.getbbox()
if not bounds:
    raise SystemExit("Could not extract the Kargozar emblem from the logo.")
emblem = emblem.crop(bounds)
foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
mark = ImageOps.contain(emblem, (620, 620), method=Image.Resampling.LANCZOS)
foreground.alpha_composite(
    mark, ((1024 - mark.width) // 2, (1024 - mark.height) // 2)
)
foreground.save(output / "android-adaptive-foreground.png", "PNG", optimize=True)

# Android 13+ themed icon mask, white artwork on transparent background.
monochrome = Image.new("RGBA", foreground.size, (255, 255, 255, 0))
monochrome.putalpha(foreground.getchannel("A"))
monochrome.save(output / "android-adaptive-monochrome.png", "PNG", optimize=True)

# Keep the exact original file alongside the generated derivatives.
shutil.copy2(source, output / "kargozar-logo-original.jpg")
print("Prepared Kargozar store icon (512x512), master (1024x1024), adaptive and monochrome assets.")
