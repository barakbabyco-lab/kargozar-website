#!/usr/bin/env python3
"""Configure a generated Flutter Android Gradle project for private release signing."""
from pathlib import Path
import re
import sys

gradle = Path("android/app/build.gradle.kts")
if not gradle.is_file():
    raise SystemExit("Expected generated Kotlin Gradle file android/app/build.gradle.kts")

source = gradle.read_text(encoding="utf-8")
if 'signingConfigs.create("release")' in source or 'create("release")' in source:
    raise SystemExit("Release signing configuration already exists; refusing to patch twice.")

imports = "import java.io.FileInputStream\nimport java.util.Properties\n"
if "import java.util.Properties" not in source:
    source = imports + source

anchor = re.search(r"(?m)^android\\s*\\{", source)
if not anchor:
    raise SystemExit("Could not locate the android { } block in generated Gradle file.")

signing = """
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
"""
properties = """val keystoreProperties = Properties().apply {
    load(FileInputStream(rootProject.file("key.properties")))
}

"""
source = source[:anchor.start()] + properties + source[anchor.start():]
# Re-find android block after inserting properties.
anchor = re.search(r"(?m)^android\\s*\\{", source)
insert_at = anchor.end()
source = source[:insert_at] + signing + source[insert_at:]

# Flutter's generated release build type defaults to the debug signing config.
release_block = re.search(r'(?s)buildTypes\\s*\\{.*?release\\s*\\{', source)
if not release_block:
    raise SystemExit("Could not locate the generated release buildType.")
tail = source[release_block.end():]
debug_signing = re.search(r'signingConfig\\s*=\\s*signingConfigs\\.getByName\\("debug"\\)', tail)
if debug_signing:
    pos = release_block.end() + debug_signing.start()
    old = debug_signing.group(0)
    source = source[:pos] + old.replace('"debug"', '"release"') + source[pos + len(old):]
else:
    # If the template has no explicit signingConfig, add it at the start of release {}.
    pos = release_block.end()
    source = source[:pos] + '\\n            signingConfig = signingConfigs.getByName("release")' + source[pos:]

gradle.write_text(source, encoding="utf-8")
print("Configured release signing in android/app/build.gradle.kts")
