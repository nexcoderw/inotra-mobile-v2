# Git Rules

## Working Tree

- Check `git status --short` before editing.
- Do not overwrite unrelated local changes.
- Do not commit `build/`, `.dart_tool/`, platform generated caches, logs, or local secrets.
- Keep changes scoped to the requested feature or fix.

## Commit Format

One commit per changed file:

```bash
git add "<path/to/file>"
git commit -m "<type>(<scope>): <short description>"
```

Allowed types:

- `feat`
- `fix`
- `chore`
- `refactor`
- `style`
- `docs`
- `test`

Examples:

```bash
git add "lib/features/main/presentation/widgets/explore_listings_feature.dart"
git commit -m "fix(explore): parse listing image fallbacks"

git add "lib/core/services/auth_session.dart"
git commit -m "fix(auth): refresh expired sessions"
```

## Before Commit

- Review the diff.
- Run `dart format` on edited Dart files.
- Run `flutter analyze` or a focused `dart analyze` command.
- Run tests for shared logic when available.
- Confirm no secrets or token values were added.

