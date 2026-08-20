# flutter-template

GitHub Template repository. Every new Flutter project starts from here.

> **Blank canvas.** No `lib/`, no `pubspec.yaml`, no Flutter code.
> The template provides the developer toolchain only.
> You initialise Flutter yourself inside the container.

[![CI](https://github.com/alihaidar0/flutter-template/actions/workflows/ci.yml/badge.svg)](https://github.com/alihaidar0/flutter-template/actions/workflows/ci.yml)
[![Build](https://github.com/alihaidar0/flutter-template/actions/workflows/build.yml/badge.svg)](https://github.com/alihaidar0/flutter-template/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## How to use

1. Click **"Use this template"** on GitHub → creates your new project repo
2. Clone it to your machine (Windows / macOS / Linux)
3. Open in VS Code → click **"Reopen in Container"** when prompted
4. VS Code pulls `alihaidar199527/flutter-devcontainer:latest` from Docker Hub
5. Your project folder is mounted at `/workspace` — full two-way sync
6. Husky git hooks activate automatically (`postCreateCommand` enables Corepack/pnpm, then runs `pnpm install`)
7. Run `flutter create` to initialise your Flutter project — see **First Steps** below
8. Start coding

---

## First Steps

Once inside the container terminal:

```bash
# 1. Initialise your Flutter project
flutter create --org com.yourcompany .
# or into a subdirectory:
flutter create --org com.yourcompany my_app

# 2. Verify the environment
flutter doctor -v

# 3. Run on web (accessible at http://localhost:8080)
frunw
# expands to: flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

Flutter is **not** initialised automatically — this is by design. You choose
the organisation ID, app name, and target platforms when you run
`flutter create`. Husky hooks are already active from step 6 above, so
there's no manual `pnpm install` step unless you're re-running it after
adding a new devDependency.

Corepack (which provides `pnpm`) ships with Node but is dormant until
enabled, and its shim lives in a root-owned path — so `postCreateCommand`
runs `sudo corepack enable` before `pnpm install`. `flutter-devcontainer`
now activates Corepack/pnpm at image build time, so this is normally a
no-op — it's kept as a safety net for older cached images.

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

## Repository Structure

```
flutter-template/
├── .devcontainer/
│   └── devcontainer.json             ← VS Code dev container config
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   └── config.yml                ← links "image" bugs to flutter-devcontainer
│   ├── workflows/
│   │   ├── build.yml                 ← production APK/AAB/Web builds
│   │   ├── ci.yml                    ← three-tier graceful-degradation CI
│   │   └── labels.yml                ← syncs labels.yml to GitHub
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── dependabot.yml                ← Actions + pub + npm, PRs → develop
│   └── labels.yml
├── .husky/
│   ├── commit-msg                    ← enforces Conventional Commits
│   ├── pre-commit                    ← format + analyze (skips pre-init)
│   └── pre-push                      ← blocks direct push to main
├── .vscode/
│   ├── extensions.json               ← host-side recommended extensions
│   ├── launch.json                   ← Flutter debug configs (forward-ready)
│   └── settings.json                 ← host-side editor defaults
├── scripts/
│   ├── entrypoint.dev.sh             ← fixes SSH/Husky permissions on start
│   └── welcome.sh                    ← tier-aware getting-started banner
├── .dockerignore
├── .editorconfig
├── .env.example
├── .gitattributes
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE                           ← MIT
├── README.md
├── SECURITY.md
├── commitlint.config.mjs
├── docker-compose.yml                ← starts the container, mounts caches
├── package.json                      ← husky + commitlint only
├── pnpm-workspace.yaml
└── repomix.config.json               ← AI-context snapshot config
```

---

## What's included

| Path                               | Purpose                                                                                         |
| ---------------------------------- | ----------------------------------------------------------------------------------------------- |
| `.devcontainer/devcontainer.json`  | VS Code dev container config — pulls pre-built image, sets `developer` user, forwards port 8080 |
| `docker-compose.yml`               | Starts the container, mounts project + SSH + Git identity + named volume caches + host emulator |
| `scripts/entrypoint.dev.sh`        | Fixes SSH key and Husky hook permissions on every container start — falls back to non-interactive `sudo` and warns instead of failing when a bind-mounted folder is root-owned |
| `scripts/welcome.sh`               | Context-aware banner — shows next steps based on project tier                                   |
| `.husky/commit-msg`                | Enforces Conventional Commits format via commitlint                                             |
| `.husky/pre-commit`                | `dart format` + `flutter analyze` (skips cleanly pre-`flutter create`)                          |
| `.husky/pre-push`                  | Blocks direct push to `main`                                                                    |
| `commitlint.config.mjs`            | Extends `@commitlint/config-conventional` with explicit type rules                              |
| `package.json`                     | Declares husky + commitlint only — no app dependencies, Node ≥ 24                               |
| `.github/workflows/ci.yml`         | Three-tier CI — graceful degradation, skips cleanly on fresh template                           |
| `.github/workflows/build.yml`      | Production builds — APK, AAB, Web — triggered on merge to `main`                                |
| `.github/workflows/labels.yml`     | Syncs `.github/labels.yml` to GitHub repository labels                                          |
| `.github/dependabot.yml`           | Weekly updates for Actions + pub + npm (Node 24 frozen) — PRs target `develop`                  |
| `.github/labels.yml`               | Label definitions — name, colour, description                                                   |
| `.github/CODEOWNERS`               | Auto-requests reviewer on every PR                                                              |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist — pinned versions, zero-code rule, target branch                                   |
| `.github/ISSUE_TEMPLATE/`          | Structured bug report + feature request forms, contact link to `flutter-devcontainer`           |
| `.vscode/extensions.json`          | Host-side extension recommendations — Dev Containers, Docker, GitLens                           |
| `.vscode/settings.json`            | Host-side editor defaults, tracked as shared team config                                        |
| `.vscode/launch.json`              | Flutter debug configurations — web server, Chrome, Android (active once `lib/main.dart` exists) |
| `.env.example`                     | Template for `.env` — copy and fill in your values                                              |
| `.editorconfig`                    | Consistent indentation/line endings across editors                                              |
| `.gitattributes`                   | Enforces LF line endings — prevents CRLF breakage on Windows                                    |
| `.gitignore`                       | Flutter, Dart, Node, Android, iOS, OS, editor, secrets                                          |
| `.dockerignore`                    | Excludes dev tooling from any future production Docker build context                            |
| `LICENSE`                          | MIT                                                                                             |
| `SECURITY.md`                      | Vulnerability reporting policy                                                                  |
| `CONTRIBUTING.md`                  | Branching model, commit convention, PR process                                                  |
| `CHANGELOG.md`                     | Keep a Changelog — tracks template-level (not app-level) changes                                |
| `repomix.config.json`              | Config for generating the AI-readable repo snapshot                                             |

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

Every job declares an explicit least-privilege `permissions: contents: read`
and a `timeout-minutes` so a stuck runner fails fast instead of hanging.

| Job       | Command                               | Purpose                                         |
| --------- | ------------------------------------- | ----------------------------------------------- |
| `format`  | `dart format --set-exit-if-changed .` | Formatting enforcement                          |
| `analyze` | `flutter analyze --fatal-infos`       | Static analysis + lint                          |
| `test`    | `flutter test --coverage`             | Unit + widget tests (skipped if no `test/` dir) |
| `audit`   | `dart pub audit`                      | Dependency vulnerability scan                   |
| `doctor`  | `flutter doctor -v`                   | Environment sanity check                        |

### `build.yml` — Production Builds

Triggered on merge to `main` (path-filtered to Flutter source files only) or
manually via workflow dispatch. Skipped entirely if `pubspec.yaml` /
`pubspec.lock` do not exist.

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

## Connecting to a Host Emulator

`docker-compose.yml` already maps `host.docker.internal` to the host gateway
(`extra_hosts: host.docker.internal:host-gateway`), so the container _can_
reach services on your host — but by default, `adb` only listens on
`localhost` on the host machine, so the container still can't see it until
you tell the host's ADB server to listen on all interfaces.

```bash
# 1. On your HOST machine (not inside the container):
#    Start (or restart) adb listening on all interfaces, not just localhost.
adb kill-server
adb -a -P 5037 nodaemon server start &

#    (Alternative: set this once in your shell profile instead of -a each time)
export ANDROID_ADB_SERVER_ADDRESS=0.0.0.0

# 2. Start the Android emulator on your host (Android Studio / avdmanager)

# 3. Inside the dev container:
adb connect host.docker.internal:5555
adbdevices          # alias for: adb devices
```

If the device shows `unauthorized`, accept the prompt on the emulator
screen. If it shows `offline`:

```bash
adbrestart           # adb kill-server && adb start-server
adb connect host.docker.internal:5555
```

> **Windows firewall:** allow inbound TCP on ports `5037` (adb server) and
> `5555` (emulator adb port) from the Docker network.

For **web**, `frunw` binds to `0.0.0.0:8080` inside the container, which
VS Code auto-forwards to `http://localhost:8080` on the host — no
emulator or `adb -a` setup required.

---

## Git Hooks

Managed by [Husky v9](https://typicode.github.io/husky/). Activated
automatically via `postCreateCommand`, which enables Corepack/pnpm and then
runs `pnpm install` when the container is created — no manual step needed.
Re-run manually with `sudo corepack enable && pnpm install` if hooks are
ever missing.

| Hook         | Trigger            | Purpose                                                                       |
| ------------ | ------------------ | ----------------------------------------------------------------------------- |
| `commit-msg` | Every `git commit` | Enforces Conventional Commits format                                          |
| `pre-commit` | Every `git commit` | `dart format` + `flutter analyze` — skips cleanly if `pubspec.yaml` is absent |
| `pre-push`   | Every `git push`   | Blocks direct push to `main`                                                  |

Hooks are re-enabled on every container start via `entrypoint.dev.sh`, which
also fixes the execute-bit permissions that Windows NTFS strips.

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
| `adbdevices`   | `adb devices`                                                      |
| `adbrestart`   | `adb kill-server && adb start-server`                              |
| `gs`           | `git status`                                                       |
| `ga`           | `git add`                                                          |
| `gc`           | `git commit -m`                                                    |
| `gp`           | `git push`                                                         |
| `gl`           | `git log --oneline --graph --decorate`                             |

---

## Platform Support

| Platform        | Build target              | Status                                                                              |
| --------------- | ------------------------- | ----------------------------------------------------------------------------------- |
| Android APK     | `flutter build apk`       | Included in `build.yml`                                                             |
| Android AAB     | `flutter build appbundle` | Included in `build.yml`                                                             |
| Web             | `flutter build web`       | Included in `build.yml`                                                             |
| iOS             | `flutter build ipa`       | Add per project — requires macOS host (Simulator can't run in this Linux container) |
| macOS Desktop   | `flutter build macos`     | Add per project — requires `macos-latest` runner                                    |
| Linux Desktop   | `flutter build linux`     | Add per project                                                                     |
| Windows Desktop | `flutter build windows`   | Add per project — requires `windows-latest` runner                                  |

---

## Dependabot

Automated dependency updates run every Monday at 09:00 UTC, opening PRs
against **`develop`** (not `main`) — matching `flutter-devcontainer`'s flow.
Promote to `main` once verified.

| Ecosystem        | Scope                | Notes                                                    |
| ---------------- | -------------------- | -------------------------------------------------------- |
| `github-actions` | All Actions versions | Grouped into one weekly PR                               |
| `pub`            | Dart packages at `/` | **Commented out by default** — see below                 |
| `npm`            | husky + commitlint   | Node 24 frozen — bump manually when Node 26 LTS is ready |

### Activating the `pub` ecosystem

The `pub` block in `.github/dependabot.yml` ships **commented out**. Dependabot
requires `pubspec.yaml` to exist to scan for dependencies, and this template
intentionally has none — leaving it enabled makes the `Dependabot` job in the
**Actions** tab fail every week with `dependency_file_not_found`.

Once you've run `flutter create` in your generated project:

1. Open `.github/dependabot.yml`
2. Uncomment the `pub` ecosystem block
3. Commit and push

Dependency updates for your Flutter packages will start on the next
scheduled run.

---

## License

MIT — see [`LICENSE`](LICENSE).

## Security

Found a vulnerability? Do not open a public issue — see
[`SECURITY.md`](SECURITY.md) for private reporting instructions.

## Contributing

Branching model, commit convention, and PR process are documented in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

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

### `pnpm install` fails — Node version mismatch or Corepack not enabled

`package.json` requires Node ≥ 24, and pins the exact pnpm version via the
`packageManager` field. `postCreateCommand` runs `sudo corepack enable`
before `pnpm install` as a safety net on images older than the point where
`flutter-devcontainer` started activating Corepack/pnpm at build time;
Corepack then reads the `packageManager` pin and downloads/enforces that
exact version automatically — no explicit `corepack prepare` step needed.
If `pnpm install` still fails, confirm `pnpm -v` matches the version pinned
in `package.json` and that you're running inside the container, not on
your host machine.

### Container start prints a permissions warning

On some hosts — especially Windows with Docker Desktop bind mounts — the
container start banner may show something like:

```
⚠️  Warning: could not fix SSH private key permissions (insufficient permissions, and no passwordless sudo available). Continuing anyway.
```

This means a bind-mounted folder (e.g. your `.ssh` directory) is owned by
`root` inside the container rather than `developer`, and no passwordless
`sudo` was available to fix it. `entrypoint.dev.sh` treats this as
non-fatal and continues starting the container rather than failing over a
permissions cosmetic issue. If SSH or Husky hooks then misbehave, check the
ownership of the affected host folder or ensure passwordless `sudo` is
available for the `developer` user.

### ADB cannot find the host emulator

The host's `adb` server binds to `localhost` by default — the container
can't reach it until you start it with `-a` (listen on all interfaces):

```bash
# On the host:
adb kill-server
adb -a -P 5037 nodaemon server start &
```

Then inside the container:

```bash
adb connect host.docker.internal:5555
adbdevices
```

If `offline`, run `adbrestart` and reconnect. On Windows, allow inbound TCP
on ports `5037` and `5555` from the Docker network in your firewall.

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

_Flutter stable · Dart · Android SDK 36 · Java 21 Temurin · Node.js 24 LTS · Husky 9 · commitlint 21 · MIT · 2026_