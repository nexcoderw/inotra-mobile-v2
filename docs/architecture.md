# Architecture Guide

The app uses a feature-oriented Flutter structure with shared core services and named routes.

## Folder Structure

```text
lib/
├── main.dart              # Bootstrap: env, Firebase, device info, notifications, auth restore
├── app.dart               # MaterialApp, providers, themes, router, observers
├── core/
│   ├── config/            # API URL, routes, router
│   ├── constants/         # Colors and endpoint constants
│   ├── guards/            # AuthGuard
│   ├── models/            # Shared models
│   ├── observers/         # Audit route observer
│   ├── repositories/      # Shared repositories
│   ├── services/          # Auth, notifications, FCM, heartbeat, chat, theme, language
│   ├── utils/             # Formatting/helpers
│   └── widgets/           # Shared widgets
├── features/
│   ├── auth/              # Authentication pages/widgets
│   ├── main/              # Main traveler shell, discovery, details, AI chat, highlights
│   └── me/                # Authenticated dashboard/provider/profile/settings area
└── i18n/                  # Language and translations
```

## Bootstrap Flow

1. `main.dart` calls `Env.load()`.
2. Firebase initializes when supported.
3. Device info and local notifications initialize.
4. Auth session restores from local storage.
5. Authenticated startup begins heartbeat, notifications, and FCM.
6. `App` creates providers and the `MaterialApp`.

## Routing

- Route names live in `lib/core/config/app_routes.dart`.
- Route construction lives in `lib/core/config/app_router.dart`.
- Protected routes use `AuthGuard.protect`.
- Keep route arguments typed or defensively parsed.

## Services

Use existing services for cross-cutting behavior:

- `AuthSession`
- `AuthStorage`
- `SessionHeartbeatService`
- `NotificationService`
- `LocalNotificationService`
- `FcmService`
- `ChatSocketService`
- `ThemeNotifier` and theme/language services

Do not add global singletons without a clear need.

## API Calls

- Build URLs with `Api.url`.
- Use endpoint constants under `lib/core/constants/api`.
- Keep parsing defensive because mobile clients often outlive backend changes.
- Use shared widgets like `AppCachedImage` for consistent media behavior.

## Feature Boundaries

- `auth`: sign-in/up and password recovery.
- `main`: public discovery, details, shell tabs, highlights, AI chat.
- `me`: authenticated dashboard, provider workflows, profile, settings.

Avoid importing deep feature widgets across unrelated domains unless they are deliberately shared.

