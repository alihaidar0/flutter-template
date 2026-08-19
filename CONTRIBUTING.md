# Contributing

Thanks for improving `flutter-template`. This repo provides the developer
toolchain and CI/CD scaffolding that every new Flutter project starts from —
changes here affect every project generated from this template.

## Branching model

- `main` — stable, always usable as a template. Protected.
- `develop` — integration branch. Dependabot PRs land here.
- `feature/**` — day-to-day work, opened as PRs into `develop`.

Open your PR against `develop` unless this is an approved release merge
into `main`.

## Before you start

Husky hooks activate automatically when the dev container is created
(`postCreateCommand` runs `pnpm install`). To re-run manually:

```bash
pnpm install
```

## Commit messages

Enforced by [Conventional Commits](https://www.conventionalcommits.org/) via
commitlint + Husky's `commit-msg` hook:

```
feat(ci): add coverage upload to test job
fix(devcontainer): correct flutterSdkPath
docs(readme): clarify emulator setup
chore(deps): bump commitlint config
```

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert` `wip`

## Making changes

- **Dev container / VS Code config** — edit `.devcontainer/devcontainer.json`
  or `.vscode/*`. Test with **Dev Containers: Rebuild Container**.
- **CI/CD workflows** — edit `.github/workflows/*.yml`. Verify the
  tier-detection logic still passes on both a fresh checkout (Tier 1 — no
  `pubspec.yaml`) and a locally-initialised project (Tier 3).
- **Git hooks** — edit `.husky/*`. These must never block a commit or push
  when `pubspec.yaml` is absent (see the Tier-1 guard in `.husky/pre-commit`).
- **Do not** add Flutter application code, a `lib/` folder, or a
  `pubspec.yaml` — this template must stay a zero-code starting point.
- **Do not** casually bump a pinned GitHub Action, Docker image tag, or SDK
  version — pinned versions are intentional. Open a dedicated PR with the
  version bump named in the title.

## Pull requests

- Fill in [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md).
- `ci.yml` must pass — it degrades gracefully on a template checkout, so it
  should never fail for reasons unrelated to your change.
- One approving review from a CODEOWNER is required before merge.

## Bugs / feature requests

Use the issue templates under **New Issue**.

## Security issues

Do not open a public issue — see [`SECURITY.md`](SECURITY.md).
