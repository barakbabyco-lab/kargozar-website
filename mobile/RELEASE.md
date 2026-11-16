# Android release preparation

## Current package identity

The Android platform is generated in CI with Flutter using:

- Dart package: `kargozar_mobile`
- Android organization: `ir.kargozar`
- Expected Android application ID: `ir.kargozar.kargozar_mobile`

The application ID is a permanent store identity after first publication. Confirm it in the generated APK/AAB manifest before creating the Bazaar listing. Do not publish under a different ID later.

## Release signing (private GitHub Actions secrets)

The Android workflow continues to build a debug APK for development. A signed release APK and AAB are built only after all four repository Actions secrets are configured:

1. `ANDROID_KEYSTORE_BASE64`: Base64-encoded contents of the release keystore.
2. `ANDROID_KEYSTORE_PASSWORD`: keystore password.
3. `ANDROID_KEY_ALIAS`: key alias.
4. `ANDROID_KEY_PASSWORD`: key password.

Create the keystore once, keep an encrypted offline backup, and never regenerate it for an update. Do not commit the keystore, `key.properties`, passwords, or API credentials. Add the four values under GitHub repository Settings → Secrets and variables → Actions. The workflow writes the keystore and properties only into its temporary runner.

After the secrets are added, run the workflow manually from Actions. The release artifacts are named `kargozar-android-release` and contain APK and AAB outputs.

## Release gates still required

- Verify the final application ID and app label in the generated Android project.
- Add a real privacy-policy URL and support contact before store submission.
- Capture genuine screenshots from the app.
- Test installation, launch, OTP, service listing, request submission, and request history on physical devices.
- Connect the app UI to the deployed production/staging API before describing these features as available.
- The first public release must use the same keystore for all future updates.

No production signing credentials or keystore are stored in this repository.
