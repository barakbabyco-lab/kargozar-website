# Kargozar

Kargozar is a nationwide, primarily remote administrative-services platform. This repository contains the customer-facing website, Android application source, and shared API backend.

## Repository structure

- `backend/`: Laravel 13 REST API for the customer app and staff portal.
- `mobile/`: Flutter Android customer application.
- `docs/`: architecture, database blueprint, API contract, OpenAPI specification and deployment readiness notes.
- `.github/workflows/`: Android build and backend test workflows.

## Current implementation status

- Laravel 13 and Sanctum foundation is committed under `backend/`.
- Staff authentication, role-protected request queue, assignment, status events, service catalog management and audit logging are implemented in the backend.
- Backend customer OTP and request APIs remain available as future capabilities; the current v1 customer app intentionally does not expose or invoke customer login, OTP, online order creation or request history.
- The current Flutter v1 app is a public service catalog: 10 main categories, 74 leaf services, 9 business companion modules, service information pages and direct phone contact.
- Customer contact CTA uses `09365952800`; customer browsing does not require an account.
- The v1 app includes About, Terms of Use and Privacy Policy pages. Public HTML copies and marketplace listing text are maintained under `docs/`.
- No production customer-order workflow, customer document upload, payment provider or e-signature provider is enabled in v1.

## Developer entry points

- Backend setup and operations: `backend/README.md`
- Backend host requirements and rollout gates: `docs/backend-readiness.md`
- Mobile setup: `mobile/README.md`
- API contract: `docs/api-contract.md`
- OpenAPI: `docs/openapi.yaml`
- Database implementation plan: `docs/database-implementation-plan.md`
- Approved multi-level service catalog: `docs/service-catalog-structure.md`

## CI

- Android: `.github/workflows/android-build.yml`
- Backend: `.github/workflows/backend-ci.yml`

Do not use real customer information in the current test environment. Never commit environment files, access tokens, SMS credentials, staff passwords or production data.
