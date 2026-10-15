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

- Optional backend API contract workflow for an app whose backend is built from the
  Django template, inert until an app pins a contract:
  - `scripts/sync-api.sh vX.Y.Z` downloads the `openapi.yaml` asset of a backend
    release with the GitHub CLI (or `--commit <sha>` before the first release),
    checks it against the release attestation (the backend template requires
    immutable releases; `gh release verify-asset`, and `--require-verified` makes a
    missing attestation an error), writes `api/openapi.yaml` and `api/BACKEND_VERSION`
    only after a successful download, and regenerates the client. The backend
    repository is read from `api/BACKEND_REPO`.
  - `scripts/generate-api.sh` runs `swagger_parser`, `build_runner` and
    `dart format` to write the committed client in `lib/api`; `swagger_parser.yaml`
    configures it (Retrofit and Dio clients with `json_serializable` models).
  - `ci.yml`: the **API client is current** job regenerates the client and fails
    when `lib/api` differs from the commit. It needs Tier 3 and `api/openapi.yaml`,
    is skipped otherwise, and is part of **CI passed**. The whitespace and final
    newline checks skip `api/openapi.yaml`, a verbatim copy of the release asset.
  - `backend-contract.yml`: an opt-in weekly check. When the repository variable
    `BACKEND_REPO` is set, it compares `api/BACKEND_VERSION` with the newest release
    of the backend and keeps one `dependencies` issue open while a newer release
    exists (closing it when the app is current). It is skipped without the
    variable, uses only `actions/checkout` and the preinstalled GitHub CLI, reads a
    private backend with the optional secret `BACKEND_READ_TOKEN` (read-only), and
    is not part of **CI passed**.
  - `docs/consuming-the-api.md` and a new optional step 7 in the README (the later
    steps are renumbered 8 to 11): one-time setup, pinning and moving to a release,
    the base URL per environment, and how the Android emulator (`10.0.2.2`) and the
    browser (`localhost`) reach a backend running on the host. `welcome.sh` shows
    the pinned release, and `lib/api/**` is marked as generated in `.gitattributes`.
- `scripts/init-readme.sh`: replaces the template guide in a new app's
  `README.md` with a short README for the app (title from the repository name,
  your description, CI/Build/License badges, platforms, a Stack table read from
  the project, the template release it started from and the license line). It
  refuses to overwrite a README that is no longer the guide unless `--force` is
  given, and the `welcome.sh` banner lists it as step 3.
- `setup-flutter-test.yml`: a smoke test of the local `setup-flutter` action
  on Linux and macOS (newest stable, a `3.x` line and an exact version). It runs
  only when the action or the workflow changes, and on demand, so it is not
  part of `CI passed`.
- `bootstrap-main.yml`: a repository created from the template starts with
  only the default branch, `develop`. This workflow creates `main` from it the
  first time it is missing (it starts on the repository's first commit, and again
  on every push to `develop` or on demand as a safety net), never
  touches an existing `main`, and never runs in the template repository itself.
  It needs only `contents: write` on its one job and is not part of `CI passed`.
- `pr-labels.yml`: adds labels to a pull request from its Conventional Commit
  title (`feat` → `feature`, `fix` → `bug`, `docs` → `documentation`, `ci` →
  `ci`, `deps` scope → `dependencies`, `!` → `breaking change`, a
  `develop` → `main` promotion → `skip-changelog`) so the generated release
  notes no longer depend on setting labels by hand. It only adds labels and is
  not part of `CI passed`.
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

- **Breaking for projects that copy the workflows: signed staging and production
  builds with draft releases.** `build.yml` now follows the branching model end to
  end (`docs/environments.md`):
  - pull requests into `develop` and `main` build a staging or production **test**
    build (APK and AAB matrix, debug key, no secrets, 14 days), as before but with
    `--flavor`; merges into `develop` and `main` run the **signed** build in the
    GitHub environment `staging` or `production` (the only job that reads the
    signing secrets): obfuscated, one APK per CPU type plus the App Bundle, the
    workflow run number as the build number, the signature verified (3 APKs, 1
    bundle, never the debug key, optionally against `ANDROID_CERT_SHA256`),
    `SHA256SUMS.txt`, and the debug symbols as a separate artifact, never in a
    release;
  - a new `release-draft` job (the only one with `contents: write`, no secrets)
    keeps the files in a **draft** release: the rolling "Staging" (tag `staging`,
    never published) for `develop` and `v<version>` for `main`, which you publish
    with one click. It finds a draft by tag or title, replaces its files, and
    leaves a published (immutable) release alone;
  - the workflow reads the application ID, the file prefix and the use of Firebase
    from the project, so it still needs no edit; Android jobs and the release job
    skip with a warning until the project defines the `staging` and `production`
    flavors, so the first pull request after `flutter create` stays green;
  - `release.yml` lost its `app-release` job, which would have published the same
    `v<version>` tag as the draft and made the release immutable before the files
    were attached; it now only publishes the template's calendar releases and is
    inert in a project (delete it there);
  - `docs/android-signing.md` is rewritten for two keys (staging and production, so
    a leaked staging key cannot sign production), the new `docs/environments.md`
    describes the flow and the flavor setup, `docs/github-setup.md` and README
    sections 7.2, 7.3 and 7.5 follow, and `.gitignore` ignores
    `android/key.*.properties` and `.signing/`.

  To adopt it in an existing project: define the two flavors and the signing
  configurations (README 7.5), create the `staging` and `production` GitHub
  environments with their secrets, copy `build.yml`, and delete `release.yml`.
- `.husky/pre-commit` now runs the checks of CI on every commit instead of only
  `dart format` on the staged Dart files: the staged files have LF endings, no
  trailing whitespace (Markdown excepted) and a final newline (the folders
  `flutter create` writes and `api/openapi.yaml` only need LF), scripts and hooks
  are executable in Git, then `dart format` (nothing is rewritten),
  `flutter analyze --fatal-infos` and `flutter test` (skipped without `test/`). It
  still skips without `pubspec.yaml` and outside the dev container, and takes about
  10 s on a small app; the README shows how to keep it fast with a `dart_test.yaml`
  tag for slow tests. The **Scripts and hooks are executable in Git** step of
  `ci.yml` moved from the template guard to the **Format** job, so it now also
  runs in a generated project (it is not template-only).
- Editor and project files for the flavor workflow: `.vscode/launch.json` runs the
  Android configuration with `--flavor staging` and gains a production one,
  `.vscode/tasks.json` gains **Run app on emulator** (connect the host emulator,
  then `flutter run --flavor staging`), and the spell checker moves from a short
  `cSpell.words` list in `.vscode/settings.json` to `cspell.json` (English, the
  Dart, Flutter and software dictionaries, `.gitignore` respected, the generated
  folders ignored) with the project's own words in `.cspell/project-words.txt`.
  `.env.example` no longer suggests loading a `.env` file with a package at
  runtime (a file with keys inside the app package is readable by anyone who
  installs it): it lists the names of build-time values, passed with
  `--dart-define-from-file`, for the two environments `staging` and `production`.
- Labels: the **Labels** workflow already runs on the first push of a repository
  created from the template (the first commit contains `.github/labels.yml`), so
  the README and `docs/github-setup.md` now say to check that the labels exist
  and to run the workflow by hand only if they are missing. `workflow_dispatch`
  stays as the fallback.
- The `wont fix` label is now `wontfix`, the name GitHub creates in every new
  repository, so the sync updates the default label instead of adding a second
  one. Existing projects keep both labels until you delete one by hand; the
  workflow never deletes labels.
- `.husky/pre-push` runs `flutter analyze --fatal-infos`, the same command as the
  CI analyze job, so an info-level lint fails before the push instead of in CI.
  The README troubleshooting entry names the flag (the `fanalyze` alias in the
  image does not pass it).
- README: step 5 and the "What to change" table tell new apps to decide the
  application ID before the first commit, because with an underscore in the
  project name Android and iOS get different IDs.
- `labels.yml` syncs `.github/labels.yml` with the `gh` CLI (`gh label create
  --force` per label, parsed with the runner's preinstalled `yq` and `jq`)
  instead of the `EndBug/label-sync` action, which still declares Node 20 and
  made every run print a deprecation warning. Behaviour is unchanged (labels
  are created or updated, unlisted labels are left alone), one third-party
  action is gone, and `EndBug/label-sync@*` is no longer needed in the allowed
  actions list (repositories that already list it can leave it).
- **`develop` is now the default branch** (set in the repository settings). Dependabot
  security updates, which always target the default branch, now arrive against
  `develop` like version updates, so nothing has to be re-targeted by hand;
  new pull requests default to it too. Rulesets, the **Verify source branch**
  job (only `develop` may target `main`) and the release flow are unchanged.
  A repository created from the template starts with `develop`; the new
  `bootstrap-main.yml` workflow creates `main` from it (see
  `docs/github-setup.md`).
- `labels.yml` also runs when `.github/labels.yml` changes on `develop`, now
  the default branch, so label edits no longer wait for a release. The setup
  guide and the README run it right after the repository is created, before the
  first pull requests, because Dependabot and `pr-labels.yml` need the labels.
- `.husky/pre-push` blocks direct pushes to `develop` as well as `main`, once the
  branch exists on the remote (creating it still works). The rulesets remain
  the real gate.
- README: apps are told to note the template release they started from and to
  read the template's Releases page to see what changed since (sections 2.4
  and 7.3).
- `scripts/pin-image.sh` follows the image's new permanent tag format
  `flutter-X.Y.Z.R` (Flutter release plus image revision): by default it pins
  the newest revision for the Flutter in the container, then resolves it to its
  digest. The old `sha-xxxxxxx` and date tags are no longer published; the
  README tag table and the bug report example are updated. The template itself
  still follows `:latest`.
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
- Release automation without a bot: GitHub Releases with generated, label-grouped
  notes are the changelog, so a project deletes `CHANGELOG.md` (a project's
  releases are the draft releases of `build.yml`, see the entry on signed builds
  below). The template keeps its calendar-versioned release in `release.yml`.
  release-please and git-cliff were not adopted:
  they need Actions to open pull requests (disabled in `docs/github-setup.md`),
  their pull requests would not trigger **CI passed** with `GITHUB_TOKEN`, and
  they would conflict with the rule that only `develop` may target `main`.
- `build.yml` gained an opt-in unsigned iOS compile check (repository variable
  `BUILD_IOS=true`, `macos-15`). Android signing is documented in
  `docs/android-signing.md` (see the entry on signed builds below).
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

### Fixed

- `pr-labels.yml` no longer cancels a run that has already started when the
  pull request title or description is edited again; only a run still waiting
  is replaced by the newest one, so editing a pull request right after opening
  it no longer leaves a cancelled run with error annotations.
- The **Format** job no longer fails the first pull request of a new app: files
  that `flutter create` writes under `android/`, `ios/`, `web/`, `macos/`,
  `linux/` and `windows/` (for example an iOS launch-image `README.md` without a
  final newline) are skipped by the trailing-whitespace and final-newline
  checks. The CRLF check and every other file are still checked.
- CI and builds no longer fail at job setup when a repository turns on
  **Require actions to be pinned to a full-length commit SHA**. That setting
  also covers the actions called inside a composite action, and the third-party
  Flutter setup action called `actions/cache` by tag. The workflows now use a
  local `.github/actions/setup-flutter` action that resolves the stable
  release from Google's release manifest, checks the SDK archive against the
  published SHA-256 and caches the SDK and the pub cache with a SHA-pinned
  `actions/cache` (Dependabot watches it). The third-party action is removed,
  so drop `subosito/flutter-action@*` from a project's allowed actions. Its
  downloads accept only HTTPS (also across redirects) and have a time limit.
- `git push` from the dev container no longer authenticates as the wrong
  GitHub account when the forwarded ssh-agent holds keys for several accounts.
  `welcome.sh` now runs the new `scripts/pin-ssh-key.sh`, which finds the key
  that belongs to the repository's account and writes a `Host` entry for the
  `origin` host alias (a plain `github.com` remote is left alone) with
  `IdentityFile` set to that key's public file and `IdentitiesOnly yes`, so ssh
  offers that one key instead of every key in the agent. No private key enters
  the container, and the pin is re-chosen when its key leaves the agent or with
  `--force`. `scripts/pin-ssh-key.sh --key SHA256:...` chooses the key
  explicitly instead of guessing (for example when two accounts can read the
  same repository): the fingerprint is remembered in the clone's `.git/config`
  as `devcontainer.sshkey`, nothing is probed, and a key missing from the agent
  is reported rather than replaced by another account's key.

## [0.1.0] — Initial template

### Added

- Dev container (`devcontainer.json`, `docker-compose.yml`) pulling the
  pre-built `flutter-devcontainer` image.
- Three-tier graceful-degradation CI (`ci.yml`) and production build
  pipeline (`build.yml`).
- Husky + commitlint git hooks.
- Dependabot for GitHub Actions, pub, and npm ecosystems (Node frozen at 24).
