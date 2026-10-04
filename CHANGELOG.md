# Changelog

All notable changes to this template are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); commit history
follows [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

> **⚠️ Revisit before Node 26 LTS:** Node's TSC voted to stop distributing
> Corepack from Node 25 onward; Node 24 still bundles it as an experimental
> feature. `flutter-devcontainer` moves to Node 26 LTS around Oct/Nov 2026.
> Corepack and pnpm are prepared in the image, so this template only runs
> `pnpm install`; the migration must keep `pnpm` on the `developer` user's
> `PATH` at the version pinned by `packageManager` (for example by installing
> pnpm in the image without Corepack) and update the `image-contract.yml`
> check if the way pnpm is provided changes.

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

- **Bumped `packageManager` from `pnpm@11.28.2` to `pnpm@12.9.1`** and
  `engines.pnpm` to `^12.0.0`. This is a **major** version bump, made together
  with `flutter-devcontainer` (which pre-caches the same version). The
  existing lockfile content is unchanged and installs with
  `--frozen-lockfile`; pnpm 12 additionally records the package manager
  itself in a leading section of `pnpm-lock.yaml`. Projects already created
  from the template keep their pinned image and stay on pnpm 11 until they
  move to the new image.
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
- The README is now the complete guide: creating an app from the template to
  the first run on an emulator and in a browser, what to change in the new app,
  GitHub settings and rulesets, branches, git inside and outside the container,
  the hooks, CI/CD, releases and troubleshooting, with 12 mermaid diagrams.
  `welcome.sh` re-installs missing Husky hooks on every start so the first
  commit and push of a new project are always checked, and
  `check-image-contract.sh` accepts the alias table under a level-2 or
  level-3 heading.
- `docs/` was listed in `.gitignore`, so `docs/github-setup.md` (linked from the
  README and CONTRIBUTING) never reached GitHub or generated projects; it is
  tracked now, together with the new `docs/android-signing.md`.
- `node_modules` moved to a named volume (`node-modules`): on a Windows bind
  mount commitlint took 9.2 s per commit and now takes 0.55 s; `entrypoint.dev.sh`
  fixes the ownership of the new mount point once.
- Release automation without a bot: `release.yml` gained an `app-release` job
  that publishes a GitHub Release with generated, label-grouped notes for the
  version in a project's `pubspec.yaml` (once per version; the Releases page is
  the changelog, so a project deletes `CHANGELOG.md`). The template keeps its
  calendar-versioned release. release-please and git-cliff were not adopted:
  they need Actions to open pull requests (disabled in `docs/github-setup.md`),
  their pull requests would not trigger **CI passed** with `GITHUB_TOKEN`, and
  they would conflict with the rule that only `develop` may target `main`.
- `docs/android-signing.md` documents Android release signing (keystore in a
  `production` environment limited to `main`, a signing job for pushes to
  `main`, a Gradle snippet that falls back to the debug key), and `build.yml`
  gained an opt-in unsigned iOS compile check (repository variable
  `BUILD_IOS=true`, `macos-15`).
- `build.yml` builds for the two environments of the branching model, so a
  generated project needs no workflow edits: pull requests into `develop`
  produce staging artifacts, pull requests into `main` and merges to `main`
  produce production artifacts (APK, AAB and web, `--dart-define=APP_ENV=…`,
  optional `env/<environment>.json`, 14 or 30 days retention), draft pull
  requests are skipped, and the three jobs became one matrix job. `ci.yml` and
  `build.yml` run `flutter pub get --enforce-lockfile`, and `ci.yml` warns
  until the dev image and the Flutter version are pinned.
  `scripts/pin-image.sh` now also writes `environment: flutter:` to
  `pubspec.yaml` and refreshes `pubspec.lock`.
- Running on the host is automatic: `scripts/connect-emulator.sh` connects the
  container's adb to an emulator on the host (at container start and, through
  the new `.vscode/tasks.json` task, before every Android launch, waiting while
  the emulator boots); `launch.json` now offers **Flutter (Android — host
  emulator)**, **Flutter (Web — host browser)** and the compound
  **Flutter (Emulator + Browser)**. The README's host section replaces the
  firewall click-path with one PowerShell command.
- Git works from the container and from the host: the Husky hooks that need the
  toolchain (`commit-msg`, `pre-commit`, the analysis in `pre-push`) skip with a
  notice outside the dev container, and CI enforces the same checks.
- Per-project version pinning: `scripts/pin-image.sh` freezes the `image:` line
  of `docker-compose.yml` to an exact `<tag>@sha256:<digest>`; `ci.yml` and
  `build.yml` install the Flutter version pinned under `environment: flutter:`
  in `pubspec.yaml` (newest stable when there is no pin); a commented-out
  Dependabot `docker-compose` block turns image updates into reviewed pull
  requests. The template itself keeps following `:latest`.
- Git identity and SSH keys are no longer bind-mounted: VS Code copies the Git
  identity and forwards the host ssh-agent (README → Git and SSH), and
  `welcome.sh` maps a host-only SSH alias in the `origin` URL to `github.com`.
  `entrypoint.dev.sh` shrinks to the Husky permission fix.
- `.husky/pre-commit` checks only the staged Dart files with `dart format`;
  `flutter analyze` moved to `.husky/pre-push`, which still blocks `main`.
- Removed `.dockerignore` (the template builds no image), the `frunc` alias
  documentation (a container cannot open Chrome), the duplicated
  Dart/Flutter extensions, `dart.flutterSdkPath` and `remoteUser` from
  `devcontainer.json` (the image's `devcontainer.metadata` label provides
  them), and the `DOCKERHUB_USERNAME` variable from the image reference.
- The dev environment relies on the current `flutter-devcontainer` image
  instead of repeating what it provides: `postCreateCommand` is just
  `pnpm install` (Corepack and pnpm are prepared in the image), and the
  `safe.directory` setting, the Gradle wrapper sync in `welcome.sh` (the
  image has no standalone Gradle) and the named-volume ownership loop in
  `entrypoint.dev.sh` are gone. **Requires the `flutter-devcontainer` image
  published after its "harden the image and publish pipeline" release.**
- `docker-compose.yml` no longer fixes `name:` or `container_name:` (projects
  created from the template no longer share one Compose project, volumes and
  container name), drops the Android SDK volume (the SDK ships in the image
  and a volume hid image updates), the custom network, `restart`, `command`,
  `:cached` and the duplicate `8080` port mapping (VS Code forwards it), and
  adds `init: true`. `GIT_SSH_COMMAND` is set once, in compose.
  `devcontainer.json` gained `hostRequirements` for Codespaces. After pulling
  a newer image run `docker compose down -v` (see README).
- `packageManager` is now `pnpm@11.28.2`, the version the dev image
  pre-caches, and `engines.pnpm` is `^11.0.0`.
- Dependabot gained a 7-day cooldown; `.github/CODEOWNERS`, labels, the
  pull-request template and the issue forms were extended; `CONTRIBUTING.md`
  and `SECURITY.md` describe the current rules and supply-chain controls.
- `.husky/commit-msg` runs `pnpm exec commitlint` instead of `npx`, matching
  the package manager the project uses.
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
