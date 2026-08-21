#!/usr/bin/env sh
set -eu

VENV_DIR="venv"

if command -v uv >/dev/null 2>&1; then
    echo "Using uv project workflow"

    if [ ! -f pyproject.toml ]; then
        uv init --bare
    fi

    UV_PROJECT_ENVIRONMENT="$VENV_DIR" uv add -r requirements.txt
else
    python3 -m venv "$VENV_DIR"
    . "$VENV_DIR/bin/activate"
    pip3 install -r requirements.txt
    deactivate
fi
