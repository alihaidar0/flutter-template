#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=/workspace

# Mark workspace as safe for git (avoids "dubious ownership" warnings).
# System scope (not --global) because ~/.gitconfig is bind-mounted read-only
# from the host (see docker-compose.yml) — writing to it fails with
# "Device or resource busy". /etc/gitconfig has no such restriction.
sudo git config --system --add safe.directory "$WORKSPACE" 2>/dev/null || true

# Auto-create .env from .env.example on first run
if [ ! -f "$WORKSPACE/.env" ] && [ -f "$WORKSPACE/.env.example" ]; then
  cp "$WORKSPACE/.env.example" "$WORKSPACE/.env"
fi

# ── Gradle wrapper version sync ─────────────────────────────────────────────
# `flutter create` pins whatever Gradle version ships with the Flutter SDK's
# own project template — unrelated to, and usually older than, the Gradle
# version this image pre-caches at $GRADLE_HOME (currently $GRADLE_VERSION,
# set in the Dockerfile). Left alone, every generated project ignores the
# pre-cached copy and silently re-downloads its own Gradle distribution on
# first build — several minutes wasted for something already sitting on disk.
# Runs on every container start so it self-heals regardless of when
# `flutter create` was run, with no manual step for the developer.
sync_gradle_wrapper() {
  local wrapper_props="$WORKSPACE/android/gradle/wrapper/gradle-wrapper.properties"
  [ -f "$wrapper_props" ] || return 0
  [ -n "${GRADLE_VERSION:-}" ] || return 0

  local current_version
  current_version=$(grep -oP 'gradle-\K[0-9]+\.[0-9]+(\.[0-9]+)?' "$wrapper_props" | head -1)

  if [ -n "$current_version" ] && [ "$current_version" != "$GRADLE_VERSION" ]; then
    sed -i -E "s/gradle-[0-9]+\.[0-9]+(\.[0-9]+)?-(bin|all)/gradle-${GRADLE_VERSION}-\2/" "$wrapper_props"
    echo "  🔧  Synced Gradle wrapper: ${current_version} → ${GRADLE_VERSION} (matches image pre-cache, avoids re-download)"
  fi
}
sync_gradle_wrapper

# ── Auto-connect to host emulator ───────────────────────────────────────────
# The container runs its own local adb server (see docker-compose.yml for why
# this replaced the earlier remote-server relay). If an emulator is already
# running on the Windows host and listening on the default port 5555, this
# connects automatically so `adb devices` / `flutter run` "just work" without
# a manual `adb connect` step every session. Silent and non-fatal if no
# emulator is running yet, or if adb isn't reachable for any reason — this is
# a convenience, not a requirement, and must never block container startup.
if command -v adb >/dev/null 2>&1; then
  timeout 3 adb connect host.docker.internal:5555 >/dev/null 2>&1 || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐦  flutter-template — dev container ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$WORKSPACE/pubspec.yaml" ] && [ -f "$WORKSPACE/pubspec.lock" ]; then
  # ── Tier 3: full project ────────────────────────────────────────────────────
  APP_NAME=$(grep '^name:' "$WORKSPACE/pubspec.yaml" | awk '{print $2}')
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  echo ""
  echo "  ✅  Flutter project detected: ${APP_NAME}"
  echo "  🔧  Flutter ${FLUTTER_VER} · Dart · Android SDK · Web"
  echo ""
  echo "  ❯ frun          flutter run"
  echo "  ❯ frunw         flutter run -d web-server (port 8080)"
  echo "  ❯ ftest         flutter test"
  echo "  ❯ fanalyze      flutter analyze"
  echo "  ❯ fdoctor       flutter doctor -v"
  echo ""
  echo "  ❯ Git aliases:  gs · ga · gc · gp · gl"
  echo "  📖  https://github.com/alihaidar0/flutter-template"

elif [ -f "$WORKSPACE/pubspec.yaml" ]; then
  # ── Tier 2: initialised but no lockfile ─────────────────────────────────────
  echo ""
  echo "  ✅  pubspec.yaml found — run flutter pub get to resolve dependencies"
  echo ""
  echo "  ┌─ Next step ──────────────────────────────────────────────────────┐"
  echo "  │  flutter pub get                                                 │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ❯ Git aliases:  gs · ga · gc · gp · gl"
  echo "  📖  https://github.com/alihaidar0/flutter-template"

else
  # ── Tier 1: fresh template ──────────────────────────────────────────────────
  echo ""
  echo "  👋  Fresh template — Flutter not yet initialised"
  echo ""
  echo "  ┌─ Step 1: Initialise Flutter project ─────────────────────────────┐"
  echo "  │  flutter create --org com.example .                              │"
  echo "  │  (replaces '.' with your own org and app name as needed)         │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ┌─ Step 2: Activate Husky git hooks ───────────────────────────────┐"
  echo "  │  pnpm install                                                    │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ┌─ Step 3: Start developing ────────────────────────────────────────┐"
  echo "  │  frunw   → run on web (port 8080)                                │"
  echo "  │  frun    → run on connected device                               │"
  echo "  │  fdoctor → check environment                                     │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  📖  https://github.com/alihaidar0/flutter-template"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
