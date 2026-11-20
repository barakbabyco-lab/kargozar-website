# Android release preparation

## Current package identity

The Android platform is generated in CI with Flutter using:

- Dart package: `kargozar_mobile`
- Android organization: `ir.kargozar`
- Expected Android application ID: `ir.kargozar.kargozar_mobile`

The application ID is a permanent store identity after first publication. Confirm it in the generated APK/AAB manifest before creating the Bazaar listing. Do not publish under a different ID later.

## App icon and Myket listing

- The Myket listing artwork is prepared at `assets/brand/myket-store-icon-512.png` (512×512 PNG, opaque background).
- The Android launcher uses generated legacy density icons plus adaptive foreground/background and Android 13+ monochrome assets from `assets/brand/`.
- The original approved logo is retained at `assets/brand/kargozar-logo-original.jpg`; derivatives can be regenerated with `python3 tool/prepare_brand_assets.py SOURCE OUTPUT_DIR`.
- The approved logo and all generated icon assets are committed in the repository; Android CI regenerates launcher resource densities from these sources.
- Before final submission, verify any additional file-size or image-format validation shown in the Myket developer console.

## Release signing (private GitHub Actions secret)

The current Android workflow expects one repository Actions secret:

- `ANDROID_SIGNING_BUNDLE_BASE64`: Base64-encoded ZIP containing:
  - `android/app/upload-keystore.jks`
  - `android/key.properties`

The `key.properties` file must contain the keystore's `storePassword`, `keyPassword`, `keyAlias`, and `storeFile` values. Keep the ZIP, keystore, properties file, and passwords private; never commit them. Create the keystore once, keep an encrypted offline backup, and use the same keystore for every future update.

After adding the secret under GitHub repository Settings → Secrets and variables → Actions, run the Android workflow manually or push an app change. When the secret is present, the workflow builds and verifies a signed release APK and AAB, then publishes them as the `kargozar-android-release` artifact. Without it, CI builds only a debug APK and skips release signing.

## Release gates still required

- Verify the final application ID and app label in the generated Android project.
- Add a real privacy-policy URL and support contact before store submission.
- Capture genuine screenshots from the app.
- Test installation, launch, OTP, service listing, request submission, and request history on physical devices.
- Connect the app UI to the deployed production/staging API before describing these features as available.
- The first public release must use the same keystore for all future updates.

No production signing credentials or keystore are stored in this repository.


## Generated Android application identity

The CI workflow applies the Persian launcher label `کارگزار` after generating the Android project and verifies that both the Gradle namespace and application ID remain `ir.kargozar.kargozar_mobile`. This keeps the store identity stable while avoiding the default technical project name on the device.
