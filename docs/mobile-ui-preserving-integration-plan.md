# Mobile API Integration Plan (Preserve Existing UI)

## Goal

Connect the existing customer-facing Flutter UI in `mobile/lib/main.dart` to the Laravel API without changing its visual design, navigation labels, spacing, colors, typography, cards, dialogs, or page layout.

The alternate implementation in `mobile/lib/app/kargozar_app.dart` is a technical reference only. It must not replace the current entry point because its widgets and layouts differ from the existing app.

## Verified repository state

- Flutter entry point: `mobile/lib/main.dart`.
- The approved customer UI and its four-tab navigation are restored in `main.dart`; the replacement UI in `app/kargozar_app.dart` is not the production entry point.
- The local `services` constant is still used by the existing Home and Services screens; service/request forms are still demonstrations until the incremental API integration is completed.
- Widget tests now assert the approved home presentation, four navigation tabs, and service-list screen.
- API infrastructure already exists:
  - `mobile/lib/core/network/kargozar_api_client.dart`
  - `mobile/lib/core/network/access_token_store.dart`
  - `mobile/lib/features/auth/customer_session.dart`
  - `mobile/lib/features/catalog/service_catalog_repository.dart`
  - `mobile/lib/features/requests/customer_request_repository.dart`
- The API client requires a build-time `API_BASE_URL` and rejects non-HTTPS remote URLs.
- The Android workflow builds with `--dart-define=API_BASE_URL` sourced from the GitHub Actions repository variable `KARGOZAR_API_BASE_URL`.
- Backend API routes are versioned under `/api/v1`.
- OTP delivery intentionally returns `503 OTP_DELIVERY_UNAVAILABLE` until a real SMS provider is configured. Do not represent OTP as production-ready before that is resolved.
- Existing Flutter tests cover API URL security, request headers, token persistence, OTP response parsing, catalog mapping, and request repository mapping.

## Confirmed integration gaps

1. `main.dart` does not instantiate or use the API client/repositories. It continues to render hard-coded service data.
2. The request form in `main.dart` is explicitly a preview and does not send data.
3. The requests page in `main.dart` is a static empty state.
4. The alternate `kargozar_app.dart` is wired to the API but has a visibly different layout. Replacing the entry point with it would violate the UI-preservation requirement.
5. The production API hostname is not yet confirmed because hosting support is still checking SSH, PHP CLI, Composer, subdomain document-root support, and database compatibility.
6. The OTP provider is not active yet; real sign-in cannot be fully verified until server-side delivery is configured.

## Safe implementation sequence

### Phase A — Preserve the existing presentation

- Keep `main.dart` as the only production app entry point.
- Keep the existing visual widget tree and styling unchanged.
- Introduce a small application-level dependency container for the API client, session, catalog repository, and request repository.
- Add state/data adapters behind existing widgets rather than copying the alternate app's screens.

### Phase B — Public catalog

- Load categories/services from the API for the existing Home and Services pages.
- Map API service identifiers, title, subtitle/description, and category to the existing `ServiceItem` view model.
- Preserve the existing icon mapping and visual cards; unknown service categories receive a neutral existing icon.
- Add loading, retry, and offline/error states using the existing typography and color palette.
- Keep the local catalog only as a clearly marked development fallback when no API base URL is configured; never silently treat fallback data as live server data.

### Phase C — Customer sign-in

- Connect the existing account entry point to the existing OTP session flow.
- Keep the current app navigation and style; implement the OTP dialog with existing theme components.
- Restore the secure token at startup and clear it on logout.
- Do not enable real OTP until the SMS adapter is configured and verified on the server.

### Phase D — Requests

- Require an authenticated customer before creating a request.
- Submit the selected API service ID and optional customer note with a fresh idempotency key.
- Display the returned tracking code in the existing confirmation style.
- Load the authenticated customer's requests and public event timeline in the existing Requests page.
- Never collect identity documents until private storage and file validation are implemented server-side.

### Phase E — Verification

- Add widget tests asserting that the existing home header, four-tab navigation, colors/styles, and service card layout remain intact.
- Add tests for loading, empty, API error/retry, unauthenticated request, successful request, and request history.
- Run `flutter analyze` and `flutter test`.
- Build a debug APK only after the correct HTTPS API URL is configured.
- Do not deploy a release APK until OTP, database, HTTPS, and production API checks pass.

## Current decision

The alternate API-backed UI was briefly made the Flutter entry point during an integration attempt. That conflicted with the approved UI-preservation decision, so the original approved `main.dart` was restored from commit `cb053771ed80d2865cdde88487a6faf7eca82a64`. The widget test was also returned to the preserved UI and expanded to cover its main screen, four-tab navigation, and services list.

The next implementation must be incremental and reviewable inside the existing `main.dart` widget tree. Do not replace the existing page layouts, visual hierarchy, labels, spacing, colors, cards, or dialogs with the alternate `kargozar_app.dart` screens. Keep API infrastructure in its separate feature modules and introduce adapters behind the approved widgets.

## Implementation progress (2026-11-18)

- Restored the approved UI as the production entry point and added a widget test for its home screen, four navigation destinations, and service list.
- The existing Services screen now reads the public service catalog over HTTPS when `API_BASE_URL` is configured. The existing page structure and list-tile presentation are retained.
- The live Services screen loads the category hierarchy and supports selecting nested categories; category selection and submitted search terms are sent to the catalog API.
- Live service detail sheets can show the catalog's requirements, estimated working days, and indicative base price. The price is explicitly labelled as requiring confirmation; no checkout or payment is implied.
- When no API URL is configured, the screen clearly labels the local catalog as demo data. If the live catalog fails, it shows an error and retry action instead of silently presenting demo data as live.
- OTP, authenticated request submission, and request-history screens are not yet connected to the preserved UI. They remain next implementation tasks after the public catalog passes CI.
- CI is currently being rerun after these changes. Do not treat the current code as verified until the newest Android workflow completes successfully.

## External prerequisites

- Hosting provider confirms PHP CLI 8.3+, Composer 2, required PHP extensions, SSH/Shell, cron, MySQL compatibility, and custom API subdomain document root.
- API subdomain and valid TLS certificate are provisioned.
- A separate production database is created.
- SMS provider credentials and template are configured only in the server environment, never in Git.
