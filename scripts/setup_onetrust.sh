#!/usr/bin/env bash
# --------------------------------------------------------------------
#  setup_onetrust.sh  –  idempotent project bootstrap for WSL Ubuntu
#
#  * clones (or pulls) private repo github.com/<YOUR-USER>/OneTrustIntegration
#  * creates/updates Python venv if requirements.txt or pyproject.toml exist
#  * installs Node deps if package.json present
#  * installs pre-commit hooks
#  * spins up accompanying docker-compose stack (if docker-compose.yml exists)
#  * opens VS Code at the end (optional)
# --------------------------------------------------------------------
set -euo pipefail

### ---- configurable bits -----------------------------------------------------
GIT_SSH_URL="git@github.com:<YOUR-USER>/OneTrustIntegration.git"
REPO_DIR="$HOME/dev/projects/OneTrustIntegration"
SECRETS_FILE="$HOME/.config/secrets/onetrust.env"   # optional
PYTHON_VERSION="python3"                            # or "python3.12"
NODE_VERSION="22"                                   # nvm alias
### ---------------------------------------------------------------------------

echo "▶  Setting up OneTrustIntegration …"

# 0. Ensure parent directories exist
mkdir -p "$(dirname "$REPO_DIR")"

# 1. Clone or pull
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "→ Cloning repository"
  git clone "$GIT_SSH_URL" "$REPO_DIR"
else
  echo "→ Pulling latest changes"
  git -C "$REPO_DIR" pull --ff-only
fi

cd "$REPO_DIR"

# 2. Python venv setup ---------------------------------------------------------
if [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  echo "→ Setting up Python virtual environment"
  if [ ! -d .venv ]; then
    $PYTHON_VERSION -m venv .venv
  fi
  source .venv/bin/activate

  echo "   • Upgrading pip & installing deps"
  pip install --upgrade pip >/dev/null
  if [ -f requirements.txt ];    then pip install -r requirements.txt; fi
  if [ -f pyproject.toml ];      then pip install -e ".[dev]"; fi
fi

# 3. Node deps -----------------------------------------------------------------
if [ -f package.json ]; then
  echo "→ Installing Node dependencies"
  nvm install "$NODE_VERSION" >/dev/null
  nvm use "$NODE_VERSION"     >/dev/null
  if [ -f package-lock.json ]; then npm ci; else npm install; fi
fi

# 4. Secrets -------------------------------------------------------------------
if [ -f "$SECRETS_FILE" ]; then
  echo "→ Loading secrets from $SECRETS_FILE"
  # shellcheck disable=SC1090
  set -a && source "$SECRETS_FILE" && set +a
else
  echo "⚠  No secrets file found at $SECRETS_FILE – skip"
fi

# 5. Pre-commit hooks ----------------------------------------------------------
if command -v pre-commit >/dev/null 2>&1 && [ -f .pre-commit-config.yaml ]; then
  echo "→ Installing pre-commit hooks"
  pre-commit install --install-hooks --overwrite
fi

# 6. Docker Compose stack ------------------------------------------------------
if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then
  echo "→ Starting docker-compose services"
  docker compose up -d
fi

# 7. Final message -------------------------------------------------------------
echo "✔  OneTrustIntegration ready."
echo "   Location: $REPO_DIR"
echo "   Activate venv with:  source $REPO_DIR/.venv/bin/activate"

# 8. (Optional) open VS Code ---------------------------------------------------
if command -v code >/dev/null 2>&1; then
  echo "→ Opening VS Code"
  code "$REPO_DIR"
fi
