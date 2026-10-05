# Contributing

## Workflow

1. Take an issue from the **To do** column on the Projects board, assign it to yourself, and move it to **In progress**.
2. Create a branch from `main`:
   ```bash
   git checkout main && git pull
   git checkout -b feature/12-home-screen
   ```
3. Commit small and often. Push, then open a Pull Request into `main`.
4. Ask **one other teammate** for a review. When it is approved and CI is green, use **Squash and merge**.
5. Delete the branch after merging. The issue closes automatically if the PR description contains `Closes #12`.

## Branch names

| Prefix | For | Example |
|---|---|---|
| `feature/` | New screen or feature | `feature/12-home-screen` |
| `fix/` | Bug fix | `fix/31-analytics-overflow` |
| `chore/` | Setup, dependencies, CI | `chore/ci-build-apk` |
| `docs/` | Documentation | `docs/readme-install` |

Format: `prefix/issue-number-short-description`.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(home): add Health Score card
fix(analytics): stress chart clipped on 360 px phones
chore: add CI workflow
```

## Code rules

- **Hardcoded data lives only in `lib/data/dummy_data.dart`.** Screens must not contain sample numbers. When we move to a backend, only this file changes.
- Always use `AppColors` and `ts()` from `theme.dart` for colors and text styles; no raw hex codes in screens.
- One screen per file in `lib/screens/`. A component used by two or more screens moves to `lib/widgets/`.
- Shared files (`theme.dart`, `widgets/common.dart`) change only through a PR reviewed by Erwin.
- Before pushing, run:
  ```bash
  dart format .
  flutter analyze
  flutter test
  ```

## Definition of done

An issue is done when:

- It matches the mockup (colors, font, spacing) and nothing overflows on a 360 px phone.
- Every button on the screen does something (at least a "coming soon" toast).
- Animations follow the Animation Flow board.
- `flutter analyze` shows no errors and CI is green.
- It has been tried on a real phone (not only an emulator), with a screenshot in the PR.
