# Operations Guide

## Local Runtime

```bash
flutter pub get
flutter run
```

Common targets:

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## Environment

```text
INOTRA_API_BASE_URL=https://api.inotra.rw/
INOTRA_API_ANDROID_BASE_URL=
INOTRA_API_IOS_BASE_URL=
INOTRA_API_WEB_BASE_URL=
GOOGLE_CLIENT_ID=
GOOGLE_MAP_API_KEY=
```

Physical devices need an API URL reachable from the device.

## Assets

- Add new assets to `pubspec.yaml`.
- Keep image assets compressed.
- Keep launcher icon source files in `assets/branding`.
- Run icon generation only when brand assets change.

## Build Commands

```bash
flutter build apk
flutter build ios
```

Release versioning is controlled by `version` in `pubspec.yaml`.

## Release Checklist

- `flutter analyze` passes.
- Relevant tests pass or blockers are documented.
- Android and iOS permission files match package behavior.
- API base URL points to production.
- Google/Firebase/Apple settings match production bundle IDs.
- Notification deep links are smoke-tested.
- App version/build number is updated when releasing.

## Runtime Risks

- Wrong API base URL breaks all network flows.
- Missing platform permissions break maps, notifications, biometrics, or media.
- Firebase initialization should not block startup on unsupported web config.
- Notification navigation can expose route bugs from cold start.

