#!/usr/bin/env bash
set -euo pipefail

# ── config ────────────────────────────────────────────────────────────
DEV_ROOT=${DEV_ROOT:-"$HOME/dev"}
NODE_VERSION=${NODE_VERSION:-"22"}          # change once, all good
PYTHON_VERSION=${PYTHON_VERSION:-"3.12.2"} # if using pyenv later
PACKAGES=(build-essential curl git unzip zsh nano ca-certificates
          gnupg lsb-release software-properties-common fzf ripgrep)

# ── helpers ───────────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1; }   # returns 0 if found, 1 if not
ensure_dir() { [[ -d "$1" ]] || mkdir -p "$1"; }

# ── directories ───────────────────────────────────────────────────────
ensure_dir "$DEV_ROOT"/{projects,configs,scripts}

# ── apt packages (idempotent) ─────────────────────────────────────────
sudo apt-get update -qq
sudo apt-get install -y "${PACKAGES[@]}"

# ── nvm & Node ────────────────────────────────────────────────────────
if ! need nvm; then
  echo "==> Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
else
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
fi

nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

# ── Python & pipx (PEP 668 compliant) ────────────────────────────────
if ! dpkg -s python3-venv >/dev/null 2>&1; then
  sudo apt install -y python3-venv
fi

# use apt, not pip, to get pipx – avoids the externally-managed error
if ! command -v pipx >/dev/null 2>&1; then
  echo "==> Installing pipx via apt"
  sudo apt install -y pipx
  pipx ensurepath
fi

# example global CLI utility
pipx install pre-commit || true

# ── docker group (skip if already done) ───────────────────────────────
if ! id -nG "$USER" | grep -q docker; then
  sudo usermod -aG docker "$USER"
  echo "==> Added $USER to docker group – log out & back in to activate"
fi

# ── VS Code extension list export for reproducibility ─────────────────
code --list-extensions > "$DEV_ROOT/configs/vscode-extensions.txt" 2>/dev/null || true
