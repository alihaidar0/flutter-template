# flutter-template

GitHub Template repository. Every new Flutter project starts from here.

> **Blank canvas.** No `lib/`, no `pubspec.yaml`, no Flutter code.
> The template provides the developer toolchain only.
> You initialise Flutter yourself inside the container.

[![CI](https://github.com/alihaidar0/flutter-template/actions/workflows/ci.yml/badge.svg)](https://github.com/alihaidar0/flutter-template/actions/workflows/ci.yml)
[![Build](https://github.com/alihaidar0/flutter-template/actions/workflows/build.yml/badge.svg)](https://github.com/alihaidar0/flutter-template/actions/workflows/build.yml)

---

## How to use

1. Click **"Use this template"** on GitHub → creates your new project repo
2. Clone it to your machine
3. Open in VS Code → click **"Reopen in Container"** when prompted
4. VS Code pulls `alihaidar199527/flutter-devcontainer:latest` from Docker Hub
5. Your project folder is mounted at `/workspace` — full two-way sync
6. Run `npm install` inside the container to activate Husky + commitlint git hooks
7. Run `flutter create` to initialise your Flutter project — see **First Steps** below
8. Start coding

---

## First Steps

Once inside the container terminal:

```bash
# 1. Activate Husky git hooks
npm install

# 2. Initialise your Flutter project
flutter create --org com.yourcompany .
# or into a subdirectory:
flutter create --org com.yourcompany my_app

# 3. Verify the environment
flutter doctor -v

# 4. Run on web (accessible at http://localhost:8080)
frunw
# expands to: flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

Flutter is **not** initialised automatically — this is by design. You choose the
organisation ID, app name, and target platforms when you run `flutter create`.

---

## Architecture

```
Two-repo system

┌──────────────────────────────────┐     ┌──────────────────────────────────┐
│  flutter-devcontainer            │     │  flutter-template  ← you are here│
│  github.com/alihaidar0/          │     │  github.com/alihaidar0/          │
│  flutter-devcontainer            │     │  flutter-template                │
│                                  │     │                                  │
│  Builds & publishes the base     │────▶│  GitHub Template — starting      │
│  Docker dev image to Docker Hub  │     │  point for every Flutter project │
└──────────────────────────────────┘     └──────────────────────────────────┘
```

When you open a Flutter project based on this template, VS Code starts the
container via Docker Compose, mounts your project folder at `/workspace`, and
forwards your host SSH keys and `.gitconfig` into the container.

---

## What's included

| Path                              | Purpose                                                                                         |
| --------------------------------- | ----------------------------------------------------------------------------------------------- |
| `.devcontainer/devcontainer.json` | VS Code dev container config — pulls pre-built image, sets `developer` user, forwards port 8080 |
| `docker-compose.yml`              | Starts the container, mounts project + SSH + Git identity + named volume caches                 |
| `scripts/entrypoint.dev.sh`       | Fixes SSH key permissions (Windows NTFS) and Husky hook permissions on every container start    |
| `scripts/welcome.sh`              | Context-aware banner — shows next steps based on project tier                                   |
| `.husky/commit-msg`               | Enforces Conventional Commits format via commitlint                                             |
| `.husky/pre-push`                 | Blocks direct push to `main`                                                                    |
| `commitlint.config.mjs`           | Extends `@commitlint/config-conventional` with explicit type rules                              |
| `package.json`                    | Declares husky + commitlint only — no app dependencies                                          |
| `.github/workflows/ci.yml`        | Three-tier CI — graceful degradation, skips cleanly on fresh template                           |
| `.github/workflows/build.yml`     | Production builds — APK, AAB, Web — triggered on merge to `main`                                |
| `.github/workflows/labels.yml`    | Syncs `.github/labels.yml` to GitHub repository labels                                          |
| `.github/dependabot.yml`          | Weekly Dependabot updates for Actions + pub + npm (Node 24 frozen)                              |
| `.github/labels.yml`              | Label definitions — name, colour, description                                                   |
| `.github/CODEOWNERS`              | Auto-requests reviewer on every PR                                                              |
| `.vscode/extensions.json`         | Host-side extension recommendations — includes Dev Containers                                   |
| `.vscode/settings.json`           | Host-side editor defaults                                                                       |
| `.vscode/launch.json`             | Flutter debug configurations — web server, Chrome, Android                                      |
| `.env.example`                    | Template for `.env` — copy and fill in your values                                              |
| `.gitattributes`                  | Enforces LF line endings — prevents CRLF breakage on Windows                                    |
| `.gitignore`                      | Flutter, Dart, Node, Android, iOS, OS, editor, secrets                                          |
| `.dockerignore`                   | Excludes dev tooling from any future production Docker build context                            |

### What is NOT included

These are intentionally absent. Add them after running `flutter create`:

```
provider / riverpod / bloc    →  flutter pub add provider
go_router                     →  flutter pub add go_router
dio / http                    →  flutter pub add dio
hive / isar / drift           →  flutter pub add hive
firebase_core                 →  flutter pub add firebase_core
any_other_package             →  flutter pub add <package>
```

Deployment workflows are also omitted — targets vary (Firebase, Play Store,
App Store, self-hosted). Add a deployment workflow per project as needed.

---

## CI/CD Pipelines

### `ci.yml` — Pull Request & Branch CI

Triggered on every push and pull request. Uses **three-tier graceful degradation**
so the CI never fails on a fresh template.

| Tier | Condition                       | What runs                                               |
| ---- | ------------------------------- | ------------------------------------------------------- |
| 1    | No `pubspec.yaml`               | Nothing — all checks skipped, CI passes automatically   |
| 2    | `pubspec.yaml` only (no lock)   | `flutter doctor` only                                   |
| 3    | `pubspec.yaml` + `pubspec.lock` | Full CI: format, analyze, test, coverage, audit, doctor |

**Job graph (Tier 3):**

```
detect ──┬── format  ──┐
         ├── analyze ──┼── test
         ├── audit      │
         └── doctor     └── ci-passed (required status check)
```

`ci-passed` is the single required status check to configure in branch protection.

| Job       | Command                               | Purpose                                         |
| --------- | ------------------------------------- | ----------------------------------------------- |
| `format`  | `dart format --set-exit-if-changed .` | Formatting enforcement                          |
| `analyze` | `flutter analyze --fatal-infos`       | Static analysis + lint                          |
| `test`    | `flutter test --coverage`             | Unit + widget tests (skipped if no `test/` dir) |
| `audit`   | `dart pub audit`                      | Dependency vulnerability scan                   |
| `doctor`  | `flutter doctor -v`                   | Environment sanity check                        |

### `build.yml` — Production Builds

Triggered on merge to `main` (path-filtered to Flutter source files only) or
manually via workflow dispatch. Skipped entirely if `pubspec.yaml` / `pubspec.lock`
do not exist.

| Job         | Runner          | Output            | Retained |
| ----------- | --------------- | ----------------- | -------- |
| `build-apk` | `ubuntu-latest` | `app-release.apk` | 14 days  |
| `build-aab` | `ubuntu-latest` | `app-release.aab` | 14 days  |
| `build-web` | `ubuntu-latest` | `build/web/`      | 14 days  |

Deployment (Play Store, Firebase App Distribution, App Store, etc.) is
intentionally omitted — add it per project depending on your target.

---

## Named Volumes

The following Docker named volumes preserve caches between container rebuilds.
Without them, every rebuild re-downloads all Flutter packages and Gradle
dependencies (~4–5 GB combined).

| Volume          | Path in container                | Purpose                      |
| --------------- | -------------------------------- | ---------------------------- |
| `pub-cache`     | `/home/developer/.pub-cache`     | Dart/Flutter package cache   |
| `gradle-cache`  | `/home/developer/.gradle`        | Gradle dependency cache      |
| `android-sdk`   | `/home/developer/Android`        | Android SDK                  |
| `shell-history` | `/home/developer/.shell_history` | Bash history across rebuilds |

---

## Git Hooks

Managed by [Husky v9](https://typicode.github.io/husky/). Activated by running
`npm install` once after cloning (or after container creation via `postCreateCommand`).

| Hook         | Trigger            | Purpose                              |
| ------------ | ------------------ | ------------------------------------ |
| `commit-msg` | Every `git commit` | Enforces Conventional Commits format |
| `pre-push`   | Every `git push`   | Blocks direct push to `main`         |

Hooks are automatically re-enabled on every container start via `entrypoint.dev.sh`,
which also fixes the execute-bit permissions that Windows NTFS strips.

---

## Commit Convention

This template uses [Conventional Commits](https://www.conventionalcommits.org/)
enforced by commitlint + Husky.

```
feat(auth): add Google Sign-In
fix(home): correct overflow on small screens
chore(deps): bump flutter_riverpod to 2.x
docs(readme): update first steps
test(auth): add unit tests for sign-in flow
refactor(home): extract HomeScreen to separate file
```

**Valid types:** `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert` `wip`

---

## Shell Aliases

All aliases are baked into the base image by `flutter-devcontainer`. A quick reference:

| Alias          | Expands to                                                         |
| -------------- | ------------------------------------------------------------------ |
| `fl`           | `flutter`                                                          |
| `frun`         | `flutter run`                                                      |
| `frunw`        | `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0` |
| `frunc`        | `flutter run -d chrome`                                            |
| `ftest`        | `flutter test`                                                     |
| `ftestc`       | `flutter test --coverage`                                          |
| `fanalyze`     | `flutter analyze`                                                  |
| `fformat`      | `dart format .`                                                    |
| `fformatcheck` | `dart format --set-exit-if-changed .`                              |
| `fdoctor`      | `flutter doctor -v`                                                |
| `fclean`       | `flutter clean`                                                    |
| `fcreate`      | `flutter create`                                                   |
| `fget`         | `flutter pub get`                                                  |
| `fadd`         | `flutter pub add`                                                  |
| `fbuildapk`    | `flutter build apk --release`                                      |
| `fbuildaab`    | `flutter build appbundle --release`                                |
| `fbuildweb`    | `flutter build web --release`                                      |
| `daudit`       | `dart pub audit`                                                   |
| `gs`           | `git status`                                                       |
| `ga`           | `git add`                                                          |
| `gc`           | `git commit -m`                                                    |
| `gp`           | `git push`                                                         |
| `gl`           | `git log --oneline --graph --decorate`                             |

---

## Platform Support

| Platform        | Build target              | Status                                             |
| --------------- | ------------------------- | -------------------------------------------------- |
| Android APK     | `flutter build apk`       | Included in `build.yml`                            |
| Android AAB     | `flutter build appbundle` | Included in `build.yml`                            |
| Web             | `flutter build web`       | Included in `build.yml`                            |
| iOS             | `flutter build ipa`       | Add per project — requires `macos-latest` runner   |
| macOS Desktop   | `flutter build macos`     | Add per project — requires `macos-latest` runner   |
| Linux Desktop   | `flutter build linux`     | Add per project                                    |
| Windows Desktop | `flutter build windows`   | Add per project — requires `windows-latest` runner |

---

## Dependabot

Automated dependency updates run every Monday at 09:00 UTC, targeting `main`.

| Ecosystem        | Scope                | Notes                                                    |
| ---------------- | -------------------- | -------------------------------------------------------- |
| `github-actions` | All Actions versions | Grouped into one weekly PR                               |
| `pub`            | Dart packages at `/` | Active once `pubspec.yaml` exists                        |
| `npm`            | husky + commitlint   | Node 24 frozen — bump manually when Node 26 LTS is ready |

---

## Troubleshooting

### `git push` fails — permission denied (publickey)

```bash
ssh-add -l            # check loaded keys
ssh -T git@github.com # verify authentication
```

On Windows, ensure the SSH agent is running before opening VS Code:

```powershell
sc config ssh-agent start= auto
net start ssh-agent
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
```

### Flutter not found after container start

The `developer` user's PATH is set in the base image. If aliases are missing,
reload the shell:

```bash
source ~/.bashrc
```

### Port 8080 not forwarding

VS Code auto-forwards port 8080. If the browser does not open automatically,
check the **Ports** tab in VS Code and open `http://localhost:8080` manually.

### `npm install` fails — node version mismatch

The `package.json` requires Node ≥ 24. The devcontainer image ships Node 24 LTS —
this should never fail inside the container. If it does, confirm you are running
inside the container and not on your host machine.

### Commit rejected — invalid commit message

Commitlint enforces the Conventional Commits format. Use one of the valid types:

```
feat fix docs style refactor perf test build ci chore revert wip
```

Example: `feat(home): add bottom navigation bar`

### Windows: shell scripts fail with `\r: command not found`

`.gitattributes` enforces LF endings for all shell scripts. If you cloned before
`.gitattributes` was in place, renormalise the repo:

```bash
git rm --cached -r .
git reset --hard HEAD
```

---

## Dev Image

|               |                                                                                                                                                 |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Image**     | `alihaidar199527/flutter-devcontainer:latest`                                                                                                   |
| **Source**    | [`github.com/alihaidar0/flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer)                                              |
| **Platforms** | `linux/amd64` · `linux/arm64`                                                                                                                   |
| **Contents**  | Flutter (stable) · Dart · Android SDK 36 · Java 21 (Temurin) · Node.js 24 LTS · Firebase CLI · FlutterFire CLI · Gradle · GitHub CLI · Starship |

---

## Related Repositories

| Repo                                                                         | Purpose                                                      |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [`flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer) | Builds and publishes the base Docker dev image               |
| [`flutter-template`](https://github.com/alihaidar0/flutter-template)         | You are here — GitHub Template for every new Flutter project |

---

_Flutter stable · Dart · Android SDK 36 · Java 21 Temurin · Node.js 24 LTS · Husky 9 · commitlint 20 · 2026_
