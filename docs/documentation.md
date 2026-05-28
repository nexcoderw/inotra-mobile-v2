# Documentation Guide

Documentation should capture durable mobile project knowledge.

## Update Docs When

- Adding a new feature area or route group.
- Changing environment variables.
- Changing auth/session/biometric behavior.
- Changing notification or deep-link behavior.
- Adding platform permissions or native configuration requirements.
- Changing release/build workflow.
- Adding a new shared service pattern.

## Where To Put Information

- `README.md`: broad project overview, setup, routes, app flow, commands.
- `AGENTS.md`: AI rules and required reading.
- `docs/git.md`: commit workflow.
- `docs/architecture.md`: feature boundaries and app structure.
- `docs/security.md`: mobile secrets, auth, storage, and data rules.
- `docs/design.md`: mobile UX and UI rules.
- `docs/testing.md`: verification strategy.
- `docs/operations.md`: builds, assets, release notes.

## Style

- Use real paths and commands.
- Keep guidance direct and maintainable.
- Do not include secrets, production tokens, or private user examples.
- Update docs only when the information should remain true beyond the current task.

