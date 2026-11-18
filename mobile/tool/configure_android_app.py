#!/usr/bin/env python3
"""Apply and verify the stable Android identity to Flutter-generated files."""

from pathlib import Path
import re
import sys

EXPECTED_APPLICATION_ID = "ir.kargozar.kargozar_mobile"
manifest = Path("android/app/src/main/AndroidManifest.xml")
gradle = Path("android/app/build.gradle.kts")

if not manifest.is_file() or not gradle.is_file():
    sys.exit("Generated Android project files were not found.")

manifest_text = manifest.read_text(encoding="utf-8")
manifest_text, replacements = re.subn(
    r'android:label="[^"]+"',
    'android:label="کارگزار"',
    manifest_text,
    count=1,
)
if replacements != 1:
    sys.exit("Could not locate the Android application label in the manifest.")
manifest.write_text(manifest_text, encoding="utf-8")

gradle_text = gradle.read_text(encoding="utf-8")
for key in ("namespace", "applicationId"):
    match = re.search(rf'{key}\s*=\s*"([^"]+)"', gradle_text)
    if not match or match.group(1) != EXPECTED_APPLICATION_ID:
        actual = match.group(1) if match else "missing"
        sys.exit(f"Unexpected Android {key}: {actual}")

print(f"Android label configured; application ID verified: {EXPECTED_APPLICATION_ID}")
