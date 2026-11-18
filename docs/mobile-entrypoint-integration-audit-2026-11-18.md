# Mobile app entrypoint and UI integration audit — 2026-11-18

## Scope

Read-only audit of the current `main` branch after pausing KPanel work. No application source or release configuration was changed during this audit.

## Confirmed findings

1. The actual Flutter entrypoint is `mobile/lib/main.dart`. Its `main()` currently calls `runApp(const KargozarApp())` where the `KargozarApp` class is implemented in that same file.
2. `mobile/lib/main.dart` still contains the earlier customer UI implementation. It has the four-tab navigation and the approved home/services visual structure, but several customer actions are informational/demo placeholders and do not use the newer authenticated request flow.
3. The newer implementation exists separately in `mobile/lib/app/kargozar_app.dart`. It contains `CustomerSession`, OTP dialog, token restoration, service catalog integration, request creation, request history, and profile login/logout.
4. The newer file defines another `KargozarApp` and another `MainShell`. It is not imported or launched by the current `main.dart`.
5. `mobile/test/widget_test.dart` imports `package:kargozar_mobile/main.dart` and explicitly asserts the earlier approved home and services UI. Simply changing the entrypoint to import `app/kargozar_app.dart` would therefore change the UI under test and is not a safe integration.
6. `mobile/README.md` currently claims that `main.dart` launches `app/kargozar_app.dart`. That statement does not match the source code and must be corrected after the integration decision is implemented.
7. Existing API client tests cover secure remote URL enforcement, OTP token persistence, authenticated requests, and idempotency headers. Catalog tests cover hierarchical categories. These tests do not currently prove that the app's actual entrypoint wires those features into the approved UI.

## Integration decision

Do not replace the approved UI with the alternate app shell and do not perform a blind entrypoint swap.

The intended implementation is to merge the newer application behavior into the existing approved UI in `mobile/lib/main.dart` (or extract the approved widgets into shared files without changing their appearance). Preserve the four existing tabs, home hero, service cards/list, typography, spacing, colors, and RTL layout while wiring:

- session restoration and signed-in state;
- OTP request and verification dialog;
- authenticated request creation from a selected service;
- idempotency key generation;
- request history and request-event display;
- profile login/logout;
- explicit, honest error states when API configuration or OTP delivery is unavailable.

Avoid duplicate top-level `KargozarApp` and `MainShell` definitions once the merge is complete. Keep the UI test assertions and extend them to cover the integrated behaviors.

## Required validation after implementation

1. Run `flutter analyze lib --no-fatal-infos`.
2. Run the full `flutter test` suite, including the approved UI regression test.
3. Confirm the app starts through the real `main.dart` entrypoint.
4. Confirm unconfigured API and disabled OTP produce clear errors, never fake success.
5. Confirm service browsing, OTP error handling, request submission, tracking code display, request history, and logout with mocked API responses.
6. Build the debug APK through GitHub Actions and inspect the artifact.
7. Only after backend HTTPS and real OTP are available, perform physical-device end-to-end tests and consider release signing.

## Current release implication

The current debug APK is not a customer-ready release. The main blocker identified by this audit is not the absence of the newer auth/request code; it is that the real app entrypoint still launches the older UI implementation. Backend HTTPS/API deployment, OTP provider approval and delivery, release signing, privacy/support information, and physical-device testing remain separate release gates.

## Deferred work

KPanel configuration and support follow-up are intentionally paused at the user's request. Do not request or change KPanel credentials or pattern settings while this work is paused.


## Implementation follow-up — 2026-11-18

The planned integration has now been implemented in the real `mobile/lib/main.dart` entrypoint.

- Converted the app root to manage the customer session, restore the saved token, and handle login/logout.
- Added an OTP dialog launched through the app's navigator context.
- Preserved the existing approved four-tab customer interface, home layout, service catalog presentation, and category tree.
- Connected service-detail actions from both the home cards and services list to the authenticated request flow.
- Added idempotency-key generation and displays the tracking code only after a successful API response.
- Connected the requests tab to the authenticated customer's request list and status events.
- Added a refresh revision after successful request creation so the requests list reloads.
- Kept sample/offline services visibly non-operational: they cannot be submitted as real server requests.
- Added widget tests for preserving the approved UI/navigation and for displaying the real API-not-configured error instead of fake OTP success. Tests use an in-memory token store.

### Validation status

- Flutter static analysis: passed on the latest workflow run.
- Flutter tests: passed on the latest workflow run, including the new widget tests and existing API/catalog tests.
- Debug APK build: running in GitHub Actions at the time this note was written; do not call the build complete until the workflow confirms success.
- Release signing: still not configured; signed APK/AAB are not yet available.
- Production API URL, HTTPS deployment, live OTP delivery, and physical-device end-to-end checks remain release blockers.

The implementation does not enable SMS OTP by itself. Keep OTP disabled on the backend until the selected SMS provider is configured and an end-to-end delivery test succeeds.
