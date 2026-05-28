# Testing and Verification Guide

## Standard Checks

```bash
dart format <changed-files>
flutter analyze
flutter test
```

Focused analysis is acceptable for narrow changes:

```bash
dart analyze lib/features/main/presentation/widgets/explore_listings_feature.dart
```

## Manual QA Focus

- Cold start.
- Auth restore and logout.
- Login/register/password reset.
- Main tab navigation.
- Listing/event/package detail pages.
- AI chat and chat threads.
- Notifications and deep links.
- Provider dashboards and submission forms.
- Light/dark theme.
- Long translated text.

## Platform Checks

For changes touching platform services, test the relevant platform:

- Android emulator for localhost remapping and push notification behavior.
- iOS simulator/device for Apple Sign-In, notifications, and permissions.
- Web only when the changed feature supports web.

## Network and Parsing

- Test loading, empty, error, and retry states.
- Keep JSON parsing defensive.
- Verify media fallbacks for missing/empty image URLs.
- Verify expired sessions do not leave protected pages usable.

