#!/usr/bin/env bash
# Makes `git push` from the container authenticate as the RIGHT GitHub account.
#
# The container has no ~/.ssh: VS Code forwards your host ssh-agent, which holds
# every key you loaded. Without a pin, ssh offers them in agent order and GitHub
# accepts the first key of ANY account, so a push can fail with "Permission to
# owner/repo.git denied to <another-account>".
#
# OpenSSH's documented fix is to name the key in the host's ssh config and set
# `IdentitiesOnly yes`: ssh then asks the agent for that one key only. A PUBLIC
# key file is enough for that (the agent holds the private half), and a public
# key is not a secret, so it is safe to keep in the container. This script:
#   1. reads the host the `origin` remote uses (`github.com` or an alias such as
#      `github.com-freelance` that only exists in your host's ~/.ssh/config),
#   2. finds the key in the agent that belongs to this repository's account: the
#      only key, or else the one GitHub greets as the repository owner, or else
#      the first one that can read the repository,
#   3. writes ~/.ssh/<host>.pub and a `Host <host>` entry with HostName
#      github.com, User git, IdentityFile <that .pub> and IdentitiesOnly yes.
# Nothing private is written, and the entry is left alone while its key is still
# in the agent. If no key can be chosen, the alias is still mapped to github.com
# and a notice says what to do.
#
# Usage: scripts/pin-ssh-key.sh [--force]
#   --force  choose the key again even if a valid pin exists (after you switched keys)
# Runs from welcome.sh on every container start; it never fails the start.
set -euo pipefail

force=0
case "${1:-}" in
  "") ;;
  --force) force=1 ;;
  *) echo "Usage: scripts/pin-ssh-key.sh [--force]" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ssh_dir="$HOME/.ssh"
config="$ssh_dir/config"

# ── The remote ───────────────────────────────────────────────────────────────
url="$(git -C "$root" remote get-url origin 2>/dev/null || true)"
host="$(sed -nE 's#^(ssh://)?git@([^:/]+)[:/].*#\2#p' <<<"$url")"
repo_path="$(sed -nE 's#^(ssh://)?git@[^:/]+[:/]+(.*)$#\2#p' <<<"$url")"
repo_path="${repo_path%.git}"
owner="${repo_path%%/*}"
if [[ "$host" != "github.com" && "$host" != github.com-* ]]; then
  exit 0 # HTTPS remote, another host or no remote: nothing to pin
fi

# ── Helpers ──────────────────────────────────────────────────────────────────
pinned_pub="$ssh_dir/${host}.pub"
mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"

# Rewrites ~/.ssh/config: drops the old `Host <host>` entry, appends a new one.
write_entry() { # [identity file]
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$config" ]]; then
    awk -v h="Host ${host}" '
      $0 == h { skip = 1; next }
      skip && /^[[:space:]]*(Host|Match)[[:space:]]/ { skip = 0 }
      !skip { print }
    ' "$config" >"$tmp"
  fi
  {
    printf 'Host %s\n  HostName github.com\n  User git\n' "$host"
    if [[ -n "${1:-}" ]]; then
      printf '  IdentityFile %s\n  IdentitiesOnly yes\n' "$1"
    fi
  } >>"$tmp"
  cat "$tmp" >"$config"
  chmod 600 "$config"
  rm -f "$tmp"
}

# Public keys the forwarded agent holds: "<type> <base64>" per line.
agent_keys() {
  ssh-add -L 2>/dev/null | awk '$1 ~ /^(ssh-|ecdsa-|sk-)/ { print $1 " " $2 }' || true
}

# ── Keep a pin that still works ──────────────────────────────────────────────
keys="$(agent_keys)"
if [[ "$host" == github.com-* ]] && ! grep -qsxF "Host ${host}" "$config"; then
  write_entry # make the alias resolve even if no key can be chosen below
fi
if [[ "$force" -eq 0 && -f "$pinned_pub" ]] \
  && grep -qsxF "  IdentityFile ${pinned_pub}" "$config" \
  && { [[ -z "$keys" ]] || grep -qF "$(awk '{ print $2 }' "$pinned_pub")" <<<"$keys"; }; then
  exit 0
fi

if [[ -z "$keys" ]]; then
  echo "  ⚠️  The ssh-agent holds no keys, so ${host} is not pinned to one."
  echo "      On the host: start the agent and 'ssh-add' the key of this repository's account,"
  echo "      then run scripts/pin-ssh-key.sh (see the README, 'Git and SSH')."
  exit 0
fi

# ── Choose the key of this repository's account ──────────────────────────────
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Probes use no config file and only the one key, so they are not affected by
# (or affecting) the entry being written.
probe_opts=(-F /dev/null -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)

# The GitHub login a key authenticates as (empty when GitHub does not know it).
login_of() { # public key file
  ssh "${probe_opts[@]}" -o "IdentityFile=$1" -T git@github.com 2>&1 \
    | sed -nE 's/^Hi ([^!]+)!.*/\1/p' | head -n 1 || true
}

can_read() { # public key file
  GIT_SSH_COMMAND="ssh ${probe_opts[*]} -o IdentityFile=$1" \
    git ls-remote "git@github.com:${repo_path}.git" >/dev/null 2>&1
}

count="$(grep -c . <<<"$keys")"
chosen="" login="" fallback="" fallback_login="" i=0
while IFS= read -r key; do
  i=$((i + 1))
  printf '%s\n' "$key" >"$work/key${i}.pub"
  if [[ "$count" -eq 1 ]]; then
    chosen="$work/key${i}.pub"
    break
  fi
  l="$(login_of "$work/key${i}.pub")"
  [[ -n "$l" ]] || continue # GitHub does not know this key
  # A deploy key is greeted as "owner/repo"; compare the owner part only.
  l_owner="${l%%/*}"
  if [[ "${l_owner,,}" == "${owner,,}" ]]; then
    chosen="$work/key${i}.pub"
    login="$l"
    break
  fi
  if [[ -z "$fallback" ]] && can_read "$work/key${i}.pub"; then
    fallback="$work/key${i}.pub"
    fallback_login="$l"
  fi
done <<<"$keys"

if [[ -z "$chosen" && -n "$fallback" ]]; then
  chosen="$fallback"
  login="$fallback_login"
fi

if [[ -z "$chosen" ]]; then
  echo "  ⚠️  Could not tell which of the ${count} keys in your ssh-agent belongs to ${repo_path}."
  echo "      On the host load only that account's key ('ssh-add -D', then 'ssh-add <key>')"
  echo "      and run scripts/pin-ssh-key.sh, or check the network and run it again."
  exit 0
fi

install -m 644 "$chosen" "$pinned_pub"
write_entry "$pinned_pub"
fingerprint="$(ssh-keygen -lf "$pinned_pub" 2>/dev/null | awk '{ print $2 }' || true)"
echo "  🔑  ${host} is pinned to one SSH key${login:+ (GitHub account ${login%%/*})}${fingerprint:+, ${fingerprint}}"
