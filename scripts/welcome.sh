#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=/workspace

# Mark workspace as safe for git (avoids "dubious ownership" warnings)
git config --global --add safe.directory "$WORKSPACE" 2>/dev/null || true

# Auto-create .env from .env.example on first run
if [ ! -f "$WORKSPACE/.env" ] && [ -f "$WORKSPACE/.env.example" ]; then
  cp "$WORKSPACE/.env.example" "$WORKSPACE/.env"
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
