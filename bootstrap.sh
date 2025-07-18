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
ensure_dir() {
  for dir in "$@"; do
    [[ -d "$dir" ]] || mkdir -p "$dir"
  done
}

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

# ── pipx install / repair (PEP-668 safe) ──────────────────────────────

# 0. Install pipx via apt if missing
if ! command -v pipx >/dev/null 2>&1; then
  echo "==> Installing pipx via apt"
  sudo apt install -y pipx
  pipx ensurepath --force        # --force silences PATH warning
fi

# 1. Clean up any zero-byte metadata files (root and venvs)
find "$HOME/.local/pipx" -type f -name 'pipx_metadata.json' -size 0 -print -delete 2>/dev/null || true

# 2. If pipx STILL errors, wipe everything and start fresh once
if ! pipx --version >/dev/null 2>&1; then
  echo "==> pipx still unhappy – resetting ~/.local/pipx completely"
  rm -rf "$HOME/.local/pipx"
  pipx ensurepath --force
fi

# 3. Install global CLI utilities (idempotent via command check)
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "==> Installing pre-commit via pipx"
  pipx install pre-commit
fi

install_docker_engine() {
  echo "==> Installing Docker Engine inside WSL via get.docker.com…"

  if command -v docker >/dev/null 2>&1; then
    echo "   • Docker CLI already present, skipping."
    return
  fi

  # 0. Remove any old distro docker packages
  sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

  # 1. Run official convenience installer (adds repo + installs engine & compose plugin)
  curl -fsSL https://get.docker.com | sudo sh

  # 2. Add user to docker group
  if ! id -nG "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "   • Added $USER to docker group – log out/in or run 'newgrp docker'"
  fi

  # 3. Smoke test
  if docker run --rm hello-world >/dev/null 2>&1; then
    echo "   ✔ Docker Engine installed and working."
  else
    echo "   ⚠ Docker installed but test container failed – troubleshoot manually."
  fi
}
if ! command -v docker >/dev/null 2>&1; then
  echo "==> WARNING: Docker CLI not found in this WSL distro."
  echo "   • Either enable WSL integration in Docker Desktop"
  echo "   • Or let the script install the native engine."
  install_docker_engine
fi

# ── docker group (skip if already done) ───────────────────────────────
if ! id -nG "$USER" | grep -q docker; then
  sudo usermod -aG docker "$USER"
  echo "==> Added $USER to docker group – log out & back in to activate"
fi

# ── VS Code extension list export for reproducibility ─────────────────
code --list-extensions > "$DEV_ROOT/configs/vscode-extensions.txt" 2>/dev/null || true

STACK_DIR="$DEV_ROOT/configs/home-dev-stacks"
if [ ! -d "$STACK_DIR" ]; then
  git clone https://github.com/your-user/home-dev-stacks.git "$STACK_DIR"
fi

cd "$STACK_DIR/n8n-stack"
docker compose up -d
