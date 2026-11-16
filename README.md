# Kargozar

Kargozar is a nationwide, primarily remote administrative-services platform. This repository contains the customer-facing website, Android application source, and shared API backend.

## Repository structure

- `backend/`: Laravel 13 REST API for the customer app and staff portal.
- `mobile/`: Flutter Android customer application.
- `docs/`: architecture, database blueprint, API contract, OpenAPI specification and deployment readiness notes.
- `.github/workflows/`: Android build and backend test workflows.

## Current implementation status

- Laravel 13 and Sanctum foundation is committed under `backend/`.
- Customer OTP, service catalog, customer request creation and customer-owned request retrieval are implemented.
- Staff authentication, role-protected request queue, assignment, status events and audit logging are implemented.
- OTP delivery remains disabled until an SMS provider is selected and configured.
- Flutter API client supports secure token persistence and session restoration. Its sample UI is not yet connected to the live API.
- No production host, database, SMS provider, customer document storage, payment provider or e-signature provider has been configured.

## Developer entry points

- Backend setup and operations: `backend/README.md`
- Backend host requirements and rollout gates: `docs/backend-readiness.md`
- Mobile setup: `mobile/README.md`
- API contract: `docs/api-contract.md`
- OpenAPI: `docs/openapi.yaml`
- Database implementation plan: `docs/database-implementation-plan.md`

## CI

- Android: `.github/workflows/android-build.yml`
- Backend: `.github/workflows/backend-ci.yml`

Do not use real customer information in the current test environment. Never commit environment files, access tokens, SMS credentials, staff passwords or production data.
