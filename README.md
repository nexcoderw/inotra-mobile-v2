# INOTRA Mobile App

Flutter mobile application for INOTRA travelers and service providers. It delivers the core travel discovery experience on mobile: listings, events, trip packages, highlights, AI chat, notifications, bookings, user profile management, provider dashboards, listing/event submission workflows, and settings.

## What This App Does

- Shows the main traveler shell with Explore, Listings, AI Chat, Events, and Highlights tabs.
- Supports login, registration, registration OTP verification, password reset, Google sign-in, Apple sign-in, and biometric/session restoration.
- Shows public listing/event/trip-package details with maps, media, reviews, services, and booking/reservation actions.
- Provides AI chat conversations and threaded chat with WebSocket support.
- Provides provider/account pages for dashboard, my listings, listing bookings, listing reviews, listing submissions, my events, event tickets, event payments, event submissions, and trip reservations.
- Handles local and push notifications through Firebase Messaging and local notification channels.
- Tracks audit route/session context for authenticated usage.
- Supports theme and language preferences.

## Tech Stack

- Flutter with Dart SDK `^3.10.4`
- Material 3
- Provider for app-level state
- `http` for REST calls
- `web_socket_channel` for chat
- `shared_preferences` for lightweight session/preferences persistence
- `flutter_secure_storage` and `local_auth` for security-related device flows
- Firebase Core, Analytics, Messaging
- Google Sign-In, Apple Sign-In, Google Maps, map launcher
- Cached network images, video player, SVG assets, file picker, share plus
- `flutter_lints` for static analysis

## Project Structure

```text
mobile/
├── android/                    # Android native project and Gradle config
├── ios/                        # iOS native project, Runner workspace, Pods
├── assets/
│   ├── branding/               # App icons and brand assets
│   ├── fonts/dm_sans/          # DMSans font family
│   ├── icons/                  # UI and language icons
│   └── images/                 # Static image/SVG assets
├── lib/
│   ├── app.dart                # MaterialApp, theme setup, router, providers
│   ├── main.dart               # App bootstrap, env, Firebase, notifications, auth restore
│   ├── core/
│   │   ├── config/             # API base URL, routes, router
│   │   ├── constants/          # App colors and API endpoint constants
│   │   ├── guards/             # Auth guard routing helpers
│   │   ├── models/             # Shared models
│   │   ├── observers/          # Audit route observer
│   │   ├── repositories/       # Shared data repositories
│   │   ├── services/           # Auth, notifications, FCM, heartbeat, theme, language, chat
│   │   ├── utils/              # Formatting and helpers
│   │   └── widgets/            # Reusable core widgets
│   ├── features/
│   │   ├── auth/               # Login, register, password reset, OTP flows
│   │   ├── main/               # Traveler shell, tabs, discovery details, chat, highlights
│   │   └── me/                 # Authenticated dashboard, provider workflows, profile/settings
│   └── i18n/                   # Language helpers and translations
├── analysis_options.yaml       # Flutter lint configuration
├── pubspec.yaml                # Dependencies, assets, fonts, launcher icons
└── README.md
```

## App Entry Flow

1. [lib/main.dart](lib/main.dart) loads `.env`, initializes Firebase where supported, resolves device info, initializes local notifications, restores the auth session, starts notification polling/FCM for authenticated users, and then runs the app.
2. [lib/app.dart](lib/app.dart) configures providers, Material 3 themes, the global navigator key, route observer, and `AppRouter`.
3. [lib/core/config/app_router.dart](lib/core/config/app_router.dart) maps all named routes and wraps protected routes with `AuthGuard`.
4. Feature pages call API endpoints through constants in `lib/core/constants/api`.

## Main Route Areas

| Area | Examples |
| --- | --- |
| Auth | `/login`, `/register`, `/verify-registration-otp`, `/forgot-password`, `/reset-password`, `/confirm-password-reset` |
| Main shell | `/home`, `/listings`, `/ai-chat`, `/events`, `/highlights` |
| Discovery details | `/trip-packages`, `/trip-package-details`, `/listing-details`, `/event-details` |
| Chat | `/ai-chat-conversations`, `/ai-chat-thread` |
| Account/provider | `/dashboard`, `/events/my`, `/listings/my`, `/trips/reservations`, `/profile` |
| Settings/legal | `/settings`, `/settings/theme`, `/settings/language`, `/privacy-policy`, `/terms-conditions`, `/contact-support` |

## Environment Variables

The app loads `.env` as an asset through `flutter_dotenv`.

```text
INOTRA_API_BASE_URL=https://api.inotra.rw/
INOTRA_API_ANDROID_BASE_URL=
INOTRA_API_IOS_BASE_URL=
INOTRA_API_WEB_BASE_URL=
GOOGLE_CLIENT_ID=
GOOGLE_MAP_API_KEY=
```

Notes:

- `INOTRA_API_BASE_URL` must include the API origin and trailing slash is normalized automatically.
- Android emulator builds remap localhost/127.0.0.1 to `10.0.2.2`.
- Physical devices need a reachable LAN or production URL.
- Mobile `.env` values are bundled into the app asset and must be treated as public.

## Local Development

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```

Useful platform commands:

```bash
flutter run -d chrome
flutter run -d ios
flutter run -d android
flutter test
flutter build apk
flutter build ios
```

## Assets and Branding

- Assets are declared in `pubspec.yaml`.
- The app uses DMSans as the global font.
- Launcher icons are generated from `assets/branding`.
- Static fallback images and SVGs are under `assets/images`.
- Keep image assets compressed and avoid adding generated build outputs to Git.

## Authentication and Session Handling

- `AuthSession` restores persisted sessions during bootstrap.
- `AuthStorage` stores token/user payloads in `SharedPreferences`.
- Token refresh and heartbeat services keep sessions alive where supported.
- `AuthGuard` protects authenticated routes and shows login prompts when needed.
- Biometric support uses `local_auth`; do not treat biometrics as backend authorization.

## Notifications and Messaging

- Firebase Messaging is used for push notification token registration.
- `LocalNotificationService` manages local notification permissions/channels and deep-link navigation.
- `NotificationService` loads cached notifications immediately, fetches from the API, and polls while authenticated.
- `ChatSocketService` handles WebSocket chat connectivity.

## Security Practices

- Never commit production `.env` values containing private secrets. Mobile environment values are public once shipped.
- Do not store long-lived secrets in `SharedPreferences`.
- Avoid logging JWTs, refresh tokens, OTPs, chat content, signed image URLs, or user PII.
- Keep all privileged authorization checks on the API; mobile guards are UX only.
- Validate file picker uploads on the server.
- Keep Firebase, Google Sign-In, Apple Sign-In, and Maps credentials restricted in their provider consoles.
- Be careful when changing notification deep links because they use the global navigator key.
- Prefer `AppCachedImage` for network images to get consistent placeholder/error behavior.

## Quality Checklist

- Run `flutter analyze` before handing off changes.
- Run `flutter test` for logic changes or shared services.
- Test route changes from cold start, authenticated state, unauthenticated state, and notification deep links when relevant.
- Test API base URL changes on Android emulator, iOS simulator, physical devices, and web if the feature supports web.
- Verify light and dark theme rendering for new UI.
- Verify long translated strings do not overflow.

## Release Notes

- Android and iOS versioning is controlled by `version` in `pubspec.yaml`.
- Android and iOS native permissions must be kept aligned with packages in use.
- Run platform builds from a clean state before release.
