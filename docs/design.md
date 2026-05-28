# Design Guide

The mobile app should feel premium, fast, clear, and travel-focused.

## Principles

- Optimize for one-handed mobile use.
- Keep primary actions visible and reachable.
- Use strong travel imagery when content depends on visual inspection.
- Keep text readable in light and dark themes.
- Provide loading, empty, error, retry, and offline-friendly states where appropriate.
- Avoid layout shifts from dynamic content.

## Components

- Prefer existing widgets before adding new primitives.
- Use `AppCachedImage` for network images.
- Use Material 3 patterns and existing icon libraries.
- Keep repeated UI under feature widgets or `core/widgets` when genuinely shared.

## Forms

- Keep forms broken into clear steps for provider submissions.
- Preserve user-entered data when API calls fail.
- Use explicit validation and clear error messages.
- Avoid cramped controls on small screens.

## Discovery UX

- Explore, listings, events, packages, and highlights should show real content quickly.
- Cards must handle missing images, long names, and missing ratings.
- Detail pages should make media, location, services, reviews, and actions easy to access.

## Accessibility and Responsive Behavior

- Text must not overflow on common device widths.
- Tap targets should be comfortable.
- Dialogs and bottom sheets must fit small screens.
- Test long translations and dynamic content.

