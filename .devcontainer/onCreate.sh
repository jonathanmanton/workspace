#!/usr/bin/env bash
# onCreate.sh — installs the toolchain into the image.
#
# This runs as `onCreateCommand`, which the devcontainer *prebuild* bakes into
# the published image (unlike postCreateCommand, which would re-run on every new
# container). So all the heavy work below happens ONCE at publish time; starting
# a container from the prebuilt image is just pull + run.
#
# Tools are installed as quiet, direct binary downloads (no Homebrew for the
# toolchain). Homebrew itself is installed for ad-hoc use later, not used here.
set -euo pipefail

# Resolve this script's dir, then copy the helper assets (bw-login.sh,
# starship.toml) to a fixed in-image location that doesn't depend on the
# workspace path — important because a prebuilt image may be launched from
# any folder (e.g. via `--devcontainer-image`).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_DIR=/usr/local/share/devcontainer
sudo mkdir -p "$ASSET_DIR"
sudo cp "$here/bw-login.sh" "$ASSET_DIR/bw-login.sh"
sudo cp "$here/starship.toml" "$ASSET_DIR/starship.toml"

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

# Helpers: download with retries (GitHub release assets can be flaky).
CURL=(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors)
fetch_bin() {  # url dest  -> single executable
  sudo "${CURL[@]}" "$1" -o "$2"
  sudo chmod +x "$2"
}
fetch_tar() {  # url tar-args...  -> extract member(s) into $BIN
  "${CURL[@]}" "$1" | sudo tar -xz -C "$BIN" "${@:2}"
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

# --- Bitwarden CLI (Node is provided by the node Feature, via nvm) ---
# Load nvm so `npm` resolves regardless of the invoking environment's PATH.
export NVM_DIR="${NVM_DIR:-/usr/local/share/nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
fi
command -v npm >/dev/null 2>&1 || export PATH="$NVM_DIR/current/bin:$PATH"
npm install -g --silent --no-fund --no-audit @bitwarden/cli

# --- jinja2-cli (the Dockerfile used pipx; uv's tool runner is the modern way) ---
uv tool install --quiet jinja2-cli   # installs into ~/.local/bin

# --- starship config (default location ~/.config/starship.toml) ---
mkdir -p "$HOME/.config"
cp "$ASSET_DIR/starship.toml" "$HOME/.config/starship.toml"

# --- Homebrew (Linuxbrew) ---
# Installed for interactive/ad-hoc use later, NOT used during this bootstrap
# (the toolchain above is installed via fast direct binaries on purpose).
if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# --- Put brew + ~/.local/bin on PATH for ALL shells ---
# A profile.d drop-in covers login shells (incl. non-interactive ones like
# VS Code tasks and remote-ssh). /usr/local/bin and the node Feature's bin dir
# are already on PATH.
sudo tee /etc/profile.d/10-devcontainer-path.sh >/dev/null <<'EOF'
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"
EOF

# --- Hook starship + the Bitwarden login prompt into interactive shells ---
# Append to ~/.bashrc (sourced by interactive shells) for the prompt + vault
# unlock. Source the asset copy so it works from a prebuilt image too.
bashrc="$HOME/.bashrc"
marker="# >>> devcontainer init >>>"
if ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
  {
    echo ""
    echo "$marker"
    echo '[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"'
    echo "source \"$ASSET_DIR/bw-login.sh\" 2>/dev/null || true"
    echo "# <<< devcontainer init <<<"
  } >> "$bashrc"
fi
