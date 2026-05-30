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

# Make sure the `bw` binary (installed via Homebrew) is on PATH.
if ! command -v bw >/dev/null 2>&1; then
  [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
command -v bw >/dev/null 2>&1 || return 0 2>/dev/null || exit 0

# Already unlocked in this shell? Nothing to do.
if [ -n "${BW_SESSION:-}" ] && \
   [ "$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null)" = "unlocked" ]; then
  return 0 2>/dev/null || exit 0
fi

case "$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null)" in
  unauthenticated)
    echo "Bitwarden: log in as ${BW_EMAIL} (Ctrl-C to skip)"
    if _bw_session="$(bw login "$BW_EMAIL" --raw)"; then
      export BW_SESSION="$_bw_session"
      echo "Bitwarden vault unlocked."
    fi
    ;;
  locked)
    echo "Bitwarden: unlock vault for ${BW_EMAIL} (Ctrl-C to skip)"
    if _bw_session="$(bw unlock --raw)"; then
      export BW_SESSION="$_bw_session"
      echo "Bitwarden vault unlocked."
    fi
    ;;
  unlocked)
    # Logged in and unlocked elsewhere, but BW_SESSION isn't in this shell.
    # Re-unlock to obtain a session key for this shell.
    echo "Bitwarden: unlock vault for ${BW_EMAIL} (Ctrl-C to skip)"
    if _bw_session="$(bw unlock --raw)"; then
      export BW_SESSION="$_bw_session"
      echo "Bitwarden vault unlocked."
    fi
    ;;
esac
unset _bw_session
