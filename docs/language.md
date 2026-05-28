# Language and Translation Rules

This mobile app must treat localization as part of production quality, not as a finishing pass.

## Supported Languages

The app currently supports five languages through `lib/i18n/translations.dart`:

- `en`: English
- `rw`: Kinyarwanda
- `fr`: French
- `es`: Spanish
- `de`: German

English is the default language. If a user has no saved or profile-provided language, `lib/i18n/lang.dart` must resolve to `en`.

## Static Text Rule

Every user-facing static string added to the Flutter UI must be translated into all supported languages before the change is considered complete.

Do not hardcode visible labels, button text, empty states, error messages, tooltips, onboarding text, section titles, or CTA copy directly in widgets. Add a translation key and read it through the existing translation helpers instead.

Acceptable exceptions are:

- API-provided content such as package titles, listing names, event names, descriptions, and user-generated text.
- Technical constants that are not displayed to users.
- Brand names that must remain unchanged.
- Short debugging-only strings that are not shipped in production UI.

## Implementation Pattern

- Add keys to every map inside `lib/i18n/translations.dart`.
- Keep keys grouped by feature prefix, for example `packages.search_hint`, `events.buy_ticket`, or `common.see_more`.
- Use `t(lang, "key")` when a widget already has a resolved `lang`.
- Use `tr("key")` only for small shared widgets that should resolve the current language internally.
- Keep English copy concise and use it as the source meaning for the other translations.
- When adding a reusable component, pass localized strings into it unless the component owns the copy.

## Review Checklist

Before finishing a mobile UI change:

- Search the changed files for new quoted visible text.
- Confirm each new static string has an entry for `en`, `rw`, `fr`, `es`, and `de`.
- Confirm English fallback behavior still resolves to `en`.
- Run focused analysis after translation changes.

## Maintenance

Update this document when the supported language list, default language behavior, translation helper pattern, or localization workflow changes.
