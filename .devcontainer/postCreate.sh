#!/usr/bin/env bash
# postCreate.sh — finishing touches that don't warrant a devcontainer Feature.
#
# Tools are installed as quiet, direct binary downloads (no Homebrew). This is
# much faster than Linuxbrew (which drags in portable-ruby, python, node, icu4c
# as dependencies) and keeps the build output quiet.
set -euo pipefail

# --- Architecture-specific naming used by the various release assets ---
case "$(uname -m)" in
  aarch64 | arm64)
    deb_arch="arm64"; gnu="aarch64-unknown-linux-gnu"; musl="aarch64-unknown-linux-musl" ;;
  *)
    deb_arch="amd64"; gnu="x86_64-unknown-linux-gnu";  musl="x86_64-unknown-linux-musl" ;;
esac

BIN=/usr/local/bin

# --- Small CLI utilities from the Dockerfile's apt block, plus tmux ---
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
  jq make bind9-dnsutils groff tmux >/dev/null

# Helpers (all quiet).
fetch_bin() {  # url dest  -> single executable
  sudo curl -fsSL "$1" -o "$2"
  sudo chmod +x "$2"
}
fetch_tar() {  # url tar-args...  -> extract member(s) into $BIN
  curl -fsSL "$1" | sudo tar -xz -C "$BIN" "${@:2}"
}

# --- Single-binary / tarball tools, all into /usr/local/bin (on PATH for all) ---
# zellij (terminal multiplexer)
fetch_tar "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${musl}.tar.gz" zellij
# starship (prompt)
fetch_tar "https://github.com/starship/starship/releases/latest/download/starship-${musl}.tar.gz" starship
# uv + uvx (Python package / tool runner)
fetch_tar "https://github.com/astral-sh/uv/releases/latest/download/uv-${gnu}.tar.gz" \
  --strip-components=1 "uv-${gnu}/uv" "uv-${gnu}/uvx"
# yq (YAML processor)
fetch_bin "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${deb_arch}" "$BIN/yq"
# argocd CLI
fetch_bin "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${deb_arch}" "$BIN/argocd"

# --- Bitwarden CLI (Node is already provided by the node Feature) ---
npm install -g --silent --no-fund --no-audit @bitwarden/cli

# --- jinja2-cli (the Dockerfile used pipx; uv's tool runner is the modern way) ---
uv tool install --quiet jinja2-cli   # installs into ~/.local/bin

# --- Put ~/.local/bin on PATH for ALL shells ---
# A profile.d drop-in covers login shells (incl. non-interactive ones like
# VS Code tasks and remote-ssh). /usr/local/bin and the node Feature's bin dir
# are already on PATH, so this is all that's needed.
sudo tee /etc/profile.d/10-devcontainer-path.sh >/dev/null <<'EOF'
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
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"'
    echo "source \"$here/bw-login.sh\" 2>/dev/null || true"
    echo "# <<< devcontainer init <<<"
  } >> "$bashrc"
fi
