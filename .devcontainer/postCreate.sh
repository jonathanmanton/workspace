#!/usr/bin/env bash
# postCreate.sh — finishing touches that don't warrant a devcontainer Feature.
set -euo pipefail

# --- Small CLI utilities from the Dockerfile's apt block, plus tmux ---
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  jq make bind9-dnsutils groff tmux

# --- Zellij (no published devcontainer Feature; install the release binary) ---
case "$(uname -m)" in
  aarch64 | arm64) zj_arch="aarch64-unknown-linux-musl" ;;
  *)               zj_arch="x86_64-unknown-linux-musl" ;;
esac
curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${zj_arch}.tar.gz" \
  | sudo tar -xz -C /usr/local/bin zellij

# --- Bitwarden CLI via Homebrew (the homebrew Feature ran already) ---
# brew isn't on PATH in this step yet, so load its shellenv first.
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install bitwarden-cli
