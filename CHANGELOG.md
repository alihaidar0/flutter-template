# Changelog

All notable changes to this template are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); commit history
follows [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

> **⚠️ Revisit before Node 26 LTS:** Node's TSC voted to stop distributing
> Corepack from Node 25 onward; Node 24 still bundles it as an experimental
> feature. `flutter-devcontainer` moves to Node 26 LTS around Oct/Nov 2026,
> at which point `sudo corepack enable` in this template's
> `devcontainer.json` `postCreateCommand` will fail
> (`corepack: command not found`). Before that migration, either add an
> explicit `npm install -g corepack` step to the base image's Dockerfile,
> or drop Corepack in favor of `pnpm`'s own self-management and update
> `postCreateCommand` accordingly.

### Added

- `.editorconfig` for consistent formatting across editors.
- `.env.example` — starter environment variable template.
- `.vscode/extensions.json`, `settings.json`, `launch.json` — shared editor
  settings and forward-ready Flutter debug configurations.
- `LICENSE` (MIT), `SECURITY.md`, `CONTRIBUTING.md`.
- `.github/PULL_REQUEST_TEMPLATE.md` and `.github/ISSUE_TEMPLATE/` (bug
  report, feature request, contact links to `flutter-devcontainer`).
- `repomix.config.json` — Repomix configuration for a single-file
  repository snapshot.
- `security` label.
- Importable rulesets for `main`, `develop` and `v*` tags
  (`.github/rulesets/`) and `docs/github-setup.md`, which lists every GitHub
  setting and the bootstrap order for the template and for each project
  created from it.
- `ci.yml` jobs: **Verify source branch** (only `develop` may target
  `main`), **Lint** (ShellCheck, actionlint), **Format**, **Commit messages**
  (commitlint over every PR commit), **Template guard** (template repository
  only) and **Dependency audit** (OSV-Scanner on `pubspec.lock`).
- `release.yml` (calendar-versioned GitHub Releases) and `image-contract.yml`
  (weekly template ↔ `flutter-devcontainer` check), both template repository
  only, plus `.github/release.yml` and the `ci` and `skip-changelog` labels.
- `.github/CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) and `pnpm-lock.yaml`.
- `ci.yml` jobs **Node dependency audit** (`pnpm audit`, high and critical
  fail) and a zizmor workflow-security step in **Lint**; the template guard
  also checks the executable bit of `.github/scripts/`.

### Changed

- The rulesets bind the required **CI passed** check to the GitHub Actions app
  (`integration_id`), `build.yml` fails when an expected artifact is missing,
  and the issue forms and PR template gained a pre-submission checklist,
  reproduction steps and a breaking-change section.
- Every workflow now pins all actions to full commit SHAs, uses
  `persist-credentials: false`, explicit `ubuntu-24.04` runners and
  `env:`-based expression handling; `ci.yml` runs on pull requests (and on
  demand) instead of on every push, and its aggregate **CI passed** job
  evaluates results through `env:`.
- Flutter CI job names are now prefixed `Flutter …` and the dependency audit
  uses OSV-Scanner instead of the third-party `dart_audit` (Dart has no
  `pub audit` command); the README no longer documents a `daudit` alias the
  image does not provide.
- VS Code configuration is deduplicated: the dev container installs the
  extensions (adding ShellCheck and GitHub Pull Requests, dropping cosmetic and
  project-specific ones), `.vscode/extensions.json` only recommends Dev
  Containers, and `.vscode/settings.json` holds the shared editor settings once
  instead of repeating `.editorconfig` and `devcontainer.json`. Removed
  `dart.lineLength` (it made the editor format at 120 while `dart format`,
  the pre-commit hook and CI use the width from `analysis_options.yaml`),
  `git.enableSmartCommit` and the Chrome launch configuration, which a
  container cannot display.
- `packageManager` is now `pnpm@11.28.2`, the version the dev image
  pre-caches, and `engines.pnpm` is `^11.0.0`.
- Dependabot gained a 7-day cooldown; `.github/CODEOWNERS`, labels, the
  pull-request template and the issue forms were extended; `CONTRIBUTING.md`
  and `SECURITY.md` describe the current rules and supply-chain controls.
- `.husky/pre-push` no longer trips ShellCheck (`read -r`, no unused
  variables); behaviour is unchanged.
- Dependabot (`github-actions`, `pub`, `npm`) now opens PRs against
  `develop` instead of `main`, matching `flutter-devcontainer`.
- `ci.yml` / `build.yml` / `labels.yml` now declare explicit least-privilege
  `permissions` and `timeout-minutes` per job. No pinned action versions
  changed.
- `.gitignore` — `.vscode/settings.json`, `extensions.json`, and
  `launch.json` are now tracked as shared team defaults; only
  `.vscode/*.local.json` is ignored.
- `devcontainer.json` `postCreateCommand` now runs `sudo corepack enable`
  before `pnpm install`, since Corepack's shim lives in a root-owned path.
  This is a safety net for images built before `flutter-devcontainer`
  started activating Corepack/pnpm at image build time. Dropped the
  earlier `corepack prepare pnpm@latest --activate` step — it silently
  ignored the `packageManager` field already pinned in `package.json`;
  `corepack enable` + `pnpm install` now lets Corepack auto-download and
  enforce that pinned version instead of always fetching the newest pnpm.
- `scripts/entrypoint.dev.sh` no longer aborts the container if it can't
  fix SSH/Husky permissions (e.g. root-owned bind mounts from Windows
  Docker Desktop). It now retries via non-interactive `sudo -n` and, if
  that also fails, prints a warning and continues rather than blocking
  container startup over a permissions cosmetic issue.
- **Bumped `packageManager` from `pnpm@10.33.0` to `pnpm@11.22.0`**
  (`engines.pnpm` floor raised to `>=11.0.0` to match). ⚠️ This is a
  **major** version bump — pnpm 11 requires Node ≥ 22 (already satisfied
  by this template's Node ≥ 24 floor), switches the store index to
  SQLite, drops the npm-CLI fallback for `pnpm publish` in favor of a
  native implementation, turns on `minimumReleaseAge` (1 day) and
  `blockExoticSubdeps` by default, and removes several legacy
  `onlyBuiltDependencies`-adjacent settings in favor of `allowBuilds`. None
  of that affects this template today (no `.npmrc`, no custom
  `onlyBuiltDependencies`/patch settings, `pnpm-workspace.yaml` only sets
  `engineStrict`/`nodeLinker`, both still valid in v11) — but re-check
  this note if you've added workspace-level pnpm config since. See
  [pnpm 11.0 release notes](https://pnpm.io/blog/releases/11.0) before
  merging if you're unsure.

## [0.1.0] — Initial template

### Added

- Dev container (`devcontainer.json`, `docker-compose.yml`) pulling the
  pre-built `flutter-devcontainer` image.
- Three-tier graceful-degradation CI (`ci.yml`) and production build
  pipeline (`build.yml`).
- Husky + commitlint git hooks.
- Dependabot for GitHub Actions, pub, and npm ecosystems (Node frozen at 24).
