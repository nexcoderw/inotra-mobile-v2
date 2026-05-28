# Security Guide

Mobile apps run on user-controlled devices. The API must enforce real security.

## Environment Values

- `.env` is bundled as an app asset.
- Treat `INOTRA_API_BASE_URL`, Google client IDs, and Maps keys as public.
- Do not place backend secrets, private API keys, signing keys, or deployment credentials in mobile `.env`.

## Authentication

- Use `AuthSession` and `AuthStorage`.
- Do not create parallel token stores.
- Do not log access tokens, refresh tokens, decoded JWTs, OTPs, or password reset data.
- Biometric auth is a local convenience and not backend authorization.

## Local Storage

- `SharedPreferences` is appropriate for lightweight session/preferences already used by the project.
- Use secure storage only for flows that require it and follow existing patterns.
- Clear session state on logout and invalid refresh behavior.

## Networking

- Use HTTPS for production.
- Keep API base URL resolution in `Env` and `Api`.
- Android emulator localhost remapping is handled by `Env`; do not duplicate it.
- Treat all API responses as untrusted and parse defensively.

## User Data

- Avoid logging PII, chat content, bookings, profile data, uploaded file metadata, signed image URLs, or notification payloads.
- Keep destructive actions behind confirmation flows.
- Keep account deletion and profile security flows explicit.

## Notifications

- Do not include sensitive content in local logs.
- Be careful with deep links from notifications because they can open protected routes.
- Validate route arguments before navigation.

