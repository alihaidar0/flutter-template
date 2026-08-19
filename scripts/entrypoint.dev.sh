#!/usr/bin/env bash
set -euo pipefail

# ── Git identity sanity check ─────────────────────────────────────────────────
# docker-compose bind-mounts the HOST's ~/.gitconfig into the container. If
# that file does not exist on the host, Docker does not error — it silently
# creates an empty DIRECTORY at that path instead. Every `git` command inside
# the container then fails with a confusing, unrelated-looking error instead
# of the real problem. Catch it here and fail fast with a clear message.
GITCONFIG="/home/developer/.gitconfig"
if [[ -d "$GITCONFIG" ]]; then
  echo "" >&2
  echo "╔══════════════════════════════════════════════════════════════════╗" >&2
  echo "║  ERROR: ~/.gitconfig was not found on the HOST machine             ║" >&2
  echo "╠══════════════════════════════════════════════════════════════════╣" >&2
  echo "║  Docker silently mounted an empty directory in its place, so all   ║" >&2
  echo "║  git commands inside this container will fail.                     ║" >&2
  echo "║                                                                      ║" >&2
  echo "║  Fix: on your HOST machine (not inside this container), run:       ║" >&2
  echo "║    git config --global user.name  \"Your Name\"                    ║" >&2
  echo "║    git config --global user.email \"you@example.com\"              ║" >&2
  echo "║                                                                      ║" >&2
  echo "║  Then rebuild the container:                                        ║" >&2
  echo "║    Dev Containers: Rebuild Container  (VS Code command palette)    ║" >&2
  echo "╚══════════════════════════════════════════════════════════════════╝" >&2
  echo "" >&2
  exit 1
fi

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
