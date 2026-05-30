#!/usr/bin/env bash
# bw-login.sh — sourced from ~/.bashrc on shell startup.
# Prompts for the Bitwarden vault master password and exports BW_SESSION so
# `bw` is ready to use for the rest of the session.

# Only run for interactive shells (skip scripts, hooks, scp, etc.).
case $- in
  *i*) ;;
  *)   return 0 2>/dev/null || exit 0 ;;
esac

BW_EMAIL="jonathan@manton.com"

# `bw` is installed globally via npm and lives on the default PATH; nothing
# extra to source here. Bail out if it's somehow missing.
command -v bw >/dev/null 2>&1 || return 0 2>/dev/null || exit 0

_bw_status() { bw status 2>/dev/null | jq -r '.status' 2>/dev/null; }

# Already unlocked in this shell? Nothing to do.
if [ -n "${BW_SESSION:-}" ] && [ "$(_bw_status)" = "unlocked" ]; then
  return 0 2>/dev/null || exit 0
fi

# Take a session key from stdin ($1=command). Only treat as success if we get a
# non-empty key that actually verifies as "unlocked" — bw can exit 0 with empty
# output when there's no TTY / the user submits nothing.
_bw_try() {
  local key
  key="$("$@")" || return 1
  [ -n "$key" ] || return 1
  if [ "$(BW_SESSION="$key" bw status 2>/dev/null | jq -r '.status' 2>/dev/null)" = "unlocked" ]; then
    export BW_SESSION="$key"
    echo "Bitwarden vault unlocked."
    return 0
  fi
  return 1
}

case "$(_bw_status)" in
  unauthenticated)
    echo "Bitwarden: log in as ${BW_EMAIL} (Ctrl-C to skip)"
    _bw_try bw login "$BW_EMAIL" --raw || echo "Bitwarden: not unlocked."
    ;;
  locked | unlocked)
    # "unlocked" here means logged in & unlocked elsewhere, but this shell has no
    # BW_SESSION — unlock again to obtain a session key for this shell.
    echo "Bitwarden: unlock vault for ${BW_EMAIL} (Ctrl-C to skip)"
    _bw_try bw unlock --raw || echo "Bitwarden: not unlocked."
    ;;
esac
