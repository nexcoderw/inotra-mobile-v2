# AGENTS.md

This file is the working agreement for AI agents modifying the INOTRA Flutter mobile app.

The mobile app is a traveler and provider experience for discovery, AI chat, highlights, notifications, listings, events, trip packages, bookings, submissions, and account management. Changes must be stable across Android, iOS, and supported web workflows.

## Required Reading

Before changing this repository, read:

- [README.md](README.md) for project overview, setup, app flow, routes, and stack.
- [docs/git.md](docs/git.md) for commit rules.
- [docs/architecture.md](docs/architecture.md) for feature boundaries and Flutter structure.
- [docs/security.md](docs/security.md) for mobile auth, storage, environment, and data handling rules.
- [docs/design.md](docs/design.md) for mobile UI and interaction standards.
- [docs/testing.md](docs/testing.md) for verification expectations.
- [docs/operations.md](docs/operations.md) for platform builds, assets, and release notes.
- [docs/documentation.md](docs/documentation.md) for documentation maintenance rules.

## Core Rules

- Keep route protection in `AuthGuard`, but rely on API authorization for real security.
- Use existing services under `lib/core/services` before adding new global behavior.
- Use endpoint constants under `lib/core/constants/api`.
- Keep features separated under `lib/features/auth`, `lib/features/main`, and `lib/features/me`.
- Treat `.env` values as public because they ship with the app.
- Do not log tokens, OTPs, chat content, signed URLs, or PII.
- Test responsive text, dark/light theme, and platform-specific behavior for UI changes.

## Documentation Maintenance

Update [README.md](README.md) or [docs/](docs/) only when a durable project rule, command, architecture pattern, environment variable, platform requirement, or release workflow changes.

## Commit Requirement

Follow [docs/git.md](docs/git.md). This repository expects one commit per changed file using Conventional Commit messages.

