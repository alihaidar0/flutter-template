#!/usr/bin/env bash
# Generates the typed API client from the pinned contract (api/openapi.yaml).
#
# One home for the generation commands: scripts/sync-api.sh runs this after it
# pins a new contract, and the "API client is current" CI job runs it to prove
# that the committed lib/api matches the contract. Run it by hand after editing
# swagger_parser.yaml or after upgrading swagger_parser, retrofit_generator or
# json_serializable.
#
#   1. swagger_parser   api/openapi.yaml  ->  lib/api (Retrofit clients, models)
#   2. build_runner     the *.g.dart files those clients and models need
#   3. dart format      so the output matches the formatter width the project
#                       uses (analysis_options.yaml), and `dart format` in CI stays green
#
# The one-time setup (the packages and swagger_parser.yaml) is described in
# docs/consuming-the-api.md.
#
# Usage: scripts/generate-api.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() {
  echo "Error: $*" >&2
  exit 1
}

# ── Preconditions ───────────────────────────────────────────────────────────
[[ -f api/openapi.yaml ]] \
  || fail "api/openapi.yaml not found. Pin a contract first: scripts/sync-api.sh vX.Y.Z"
[[ -f swagger_parser.yaml ]] \
  || fail "swagger_parser.yaml not found (the template ships it at the repository root)."
[[ -f pubspec.yaml ]] \
  || fail "pubspec.yaml not found. Run 'flutter create' first (README, step 5)."
command -v dart >/dev/null 2>&1 \
  || fail "dart is not on the PATH. Run this inside the dev container."

if ! grep -Eq '^[[:space:]]+swagger_parser:' pubspec.yaml; then
  fail "swagger_parser is not a dev dependency of this project. Run:
  flutter pub add dio retrofit json_annotation
  flutter pub add --dev build_runner json_serializable retrofit_generator swagger_parser"
fi

# A Flutter project needs `flutter pub get` (not `dart pub get`) before `dart run`.
if [[ ! -f .dart_tool/package_config.json ]]; then
  command -v flutter >/dev/null 2>&1 || fail "flutter is not on the PATH. Run this inside the dev container."
  flutter pub get
fi

# ── Generate ────────────────────────────────────────────────────────────────
echo "Generating the API client from api/openapi.yaml into lib/api ..."
dart run swagger_parser
dart run build_runner build --delete-conflicting-outputs
dart format lib/api

echo "Done. Review and commit lib/api."
