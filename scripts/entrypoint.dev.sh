#!/usr/bin/env bash
set -euo pipefail

# ── SSH key permissions ───────────────────────────────────────────────────────
# Windows NTFS does not preserve Unix file permissions. Keys mounted from a
# Windows host arrive with 0777 permissions, which SSH rejects. Fix them on
# every container start so `git push` via SSH always works.
SSH_DIR="/home/developer/.ssh"
if [[ -d "$SSH_DIR" ]]; then
  chmod 700 "$SSH_DIR"
  find "$SSH_DIR" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
  find "$SSH_DIR" -type f -name "*.pub"                 -exec chmod 644 {} +
  find "$SSH_DIR" -type f \( -name "config" -o -name "known_hosts*" \) \
                            -exec chmod 600 {} +
fi

# ── Husky hook permissions ────────────────────────────────────────────────────
# Windows NTFS strips the execute bit from shell scripts. Without it, git
# refuses to run the hook and silently skips commit-msg / pre-push enforcement.
HUSKY_DIR="/workspace/.husky"
if [[ -d "$HUSKY_DIR" ]]; then
  find "$HUSKY_DIR" -type f ! -name "*.md" -exec chmod +x {} +
fi

# ── Entrypoint dispatch ───────────────────────────────────────────────────────
# When called with arguments (e.g. from docker run), exec them directly.
# When called with no arguments (VS Code devcontainer mode), hand off to the
# CMD from the image (sleep infinity).
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec sleep infinity
fi
