#!/usr/bin/env bash
# =============================================================
#  check-tool-versions.sh — are the linter versions CI pins still current?
#
#  ci.yml pins actionlint and zizmor with the `version:` input of their actions;
#  without it the actions run the newest release, and Lint could fail on a day
#  nothing in the repository changed. No Dependabot ecosystem reads those inputs,
#  so the weekly Image contract run (template only) compares each pin with the
#  newest release that is at least COOLDOWN_DAYS old (default 7, the same
#  cooldown Dependabot uses) and fails while a pin is behind it. Bump the line in
#  ci.yml in a pull request, read the release notes, and let Lint run.
#
#  A release feed that cannot be read is a warning, not a failure.
#  Run from the repository root. Needs curl, jq and sort -V. GITHUB_TOKEN, when
#  set, raises the GitHub API rate limit.
# =============================================================
set -euo pipefail

cooldown_days="${COOLDOWN_DAYS:-7}"
now="$(date -u +%s)"
status=0

# The `version:` input of the ci.yml step that uses the given action.
pinned() {
  awk -v action="$1" '
    index($0, "uses: " action "@") { found = 1; next }
    found && /^[[:space:]]*- name:/ { exit }
    found && /^[[:space:]]*version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/ {
      sub(/^[[:space:]]*version:[[:space:]]*/, ""); print $1; exit
    }' .github/workflows/ci.yml
}

# The newest release of a GitHub repository published at least cooldown_days
# ago, without a leading "v". Drafts and pre-releases are skipped.
newest_mature() {
  local auth=()
  if [ -n "${GITHUB_TOKEN:-}" ]; then auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}"); fi
  curl -fsS --max-time 30 "${auth[@]}" "https://api.github.com/repos/$1/releases?per_page=30" \
    | jq -r --argjson now "${now}" --argjson days "${cooldown_days}" '
        [ .[] | select(.draft == false and .prerelease == false)
              | select(($now - (.published_at | fromdateiso8601)) >= ($days * 86400)) ]
        | first | .tag_name // empty | ltrimstr("v")'
}

check() { # tool name, action, release repository
  local pin newest
  pin="$(pinned "$2")"
  if [ -z "${pin}" ]; then
    echo "::error::ci.yml pins no ${1} version (a 'version: X.Y.Z' input on the $2 step)."
    status=1
    return
  fi
  if ! newest="$(newest_mature "$3")" || [ -z "${newest}" ]; then
    echo "::warning::Could not read the releases of $3; ${1} ${pin} was not checked."
    return
  fi
  if [ "${pin}" != "${newest}" ] \
    && [ "$(printf '%s\n%s\n' "${pin}" "${newest}" | sort -V | tail -1)" = "${newest}" ]; then
    echo "::error::${1}: ci.yml pins ${pin}, but ${newest} was released at least ${cooldown_days} days ago. Set 'version: ${newest}' on the $2 step in .github/workflows/ci.yml, read its release notes and let Lint run."
    status=1
  else
    echo "${1} ${pin} is current (newest release older than ${cooldown_days} days: ${newest})."
  fi
}

check actionlint raven-actions/actionlint rhysd/actionlint
check zizmor zizmorcore/zizmor-action zizmorcore/zizmor
exit "${status}"
