#!/usr/bin/env bash
# postCreate.sh — finishing touches that don't warrant a devcontainer Feature.
#
# Why so much lives here instead of in "features":
# the devcontainers-extra "via Github Releases" Features (starship, zellij,
# eksctl, yq, argo-cd, homebrew) all fail in this environment with curl exit 60
# (their bundled downloader doesn't trust the network's proxy CA). Installing
# the same tools via apt / Homebrew / official tarballs is reliable, so that's
# what we do here.
set -euo pipefail

# --- Small CLI utilities from the Dockerfile's apt block, plus tmux ---
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  jq make bind9-dnsutils groff tmux build-essential procps file

# --- Zellij (install the official release binary, arch-aware) ---
case "$(uname -m)" in
  aarch64 | arm64) zj_arch="aarch64-unknown-linux-musl" ;;
  *)               zj_arch="x86_64-unknown-linux-musl" ;;
esac
curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${zj_arch}.tar.gz" \
  | sudo tar -xz -C /usr/local/bin zellij

# --- Homebrew (Linuxbrew) ---
# Install non-interactively, then load its shellenv for the brew install below.
if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# --- Tools installed via Homebrew ---
# starship, eksctl, yq, argocd, uv, and the Bitwarden CLI are all brew formulae.
brew install starship eksctl yq argocd uv bitwarden-cli

# --- jinja2-cli (the Dockerfile installed it via pipx; use uv's tool runner) ---
uv tool install jinja2-cli

# --- Put brew (and ~/.local/bin) on PATH for ALL shells ---
# A profile.d drop-in covers login shells (incl. non-interactive ones like
# VS Code tasks and remote-ssh), so the brew-installed tools always resolve.
sudo tee /etc/profile.d/10-devcontainer-path.sh >/dev/null <<'EOF'
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"
EOF

# --- Hook starship + the Bitwarden login prompt into interactive shells ---
# Append to ~/.bashrc (sourced by interactive shells) for the prompt + vault
# unlock. postCreate runs from the workspace folder, so resolve paths now.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bashrc="$HOME/.bashrc"
marker="# >>> devcontainer init >>>"
if ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
  {
    echo ""
    echo "$marker"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"'
    echo "source \"$here/bw-login.sh\" 2>/dev/null || true"
    echo "# <<< devcontainer init <<<"
  } >> "$bashrc"
fi
