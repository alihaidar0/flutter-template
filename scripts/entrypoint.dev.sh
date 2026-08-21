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

# ── Helper: run a command as-is, fall back to non-interactive sudo, else warn ──
# Bind-mounted folders from a Windows host are frequently owned by root inside
# the container (Docker Desktop does not remap ownership for Windows binds).
# A plain `chmod` as the non-root `developer` user then fails with
# "Operation not permitted". We try the fix, escalate via `sudo -n` (no
# password prompt — avoids hanging in non-interactive container startup), and
# if even that fails, we warn and continue rather than kill the whole
# container over a permissions cosmetic issue.
run_or_warn() {
  local description="$1"
  shift
  if "$@" 2>/dev/null; then
    return 0
  fi
  if sudo -n "$@" 2>/dev/null; then
    return 0
  fi
  echo "⚠️  Warning: could not fix $description (insufficient permissions, and no passwordless sudo available). Continuing anyway." >&2
  return 0
}

# ── SSH key permissions ───────────────────────────────────────────────────────
# Windows NTFS does not preserve Unix file permissions. Keys mounted from a
# Windows host arrive with permissions SSH rejects. Fix them on every
# container start so `git push` via SSH always works.
SSH_DIR="/home/developer/.ssh"
if [[ -d "$SSH_DIR" ]]; then
  run_or_warn "SSH directory permissions" chmod 700 "$SSH_DIR"
  run_or_warn "SSH private key permissions" find "$SSH_DIR" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
  run_or_warn "SSH public key permissions"  find "$SSH_DIR" -type f -name "*.pub"                 -exec chmod 644 {} +
  run_or_warn "SSH config/known_hosts permissions" find "$SSH_DIR" -type f \( -name "config" -o -name "known_hosts*" \) \
                            -exec chmod 600 {} +
fi

# ── Named volume ownership ────────────────────────────────────────────────────
# Docker creates a fresh named volume's mount point owned by root, since no
# process runs as root to initialise it before the container's entrypoint
# fires. The non-root `developer` user then has no write access — Gradle,
# for example, fails to create its wrapper distribution lock file with a
# misleading "error while downloading artifacts from the network" message,
# when the real cause is a plain permissions problem, not the network.
# Only need to actually chown when still root-owned; skip the no-op cost on
# every subsequent start once corrected once.
for dir in "/home/developer/.gradle" "/home/developer/.pub-cache" "/home/developer/Android"; do
  if [[ -d "$dir" ]] && [[ "$(stat -c '%U' "$dir")" != "developer" ]]; then
    run_or_warn "ownership of $dir" sudo chown -R developer:developer "$dir"
  fi
done

# ── Husky hook permissions ────────────────────────────────────────────────────
# Windows NTFS strips the execute bit from shell scripts. Without it, git
# refuses to run the hook and silently skips commit-msg / pre-push enforcement.
HUSKY_DIR="/workspace/.husky"
if [[ -d "$HUSKY_DIR" ]]; then
  run_or_warn "Husky hook execute permissions" find "$HUSKY_DIR" -type f ! -name "*.md" -exec chmod +x {} +
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
