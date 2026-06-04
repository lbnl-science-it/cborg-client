#!/usr/bin/env bash
# Launches two containers via podman:
#   1. qdrant  -- vector database, bound to localhost:6333
#   2. cborg-embed-proxy -- nginx reverse proxy that injects the CBorg API key
#      into embeddings requests, bound to localhost:8929.
#
# The proxy exists because roocode's codebase-index openai-compatible mode has
# no field for an API key, so we run a local proxy that adds the Authorization
# header from $CBORG_API_KEY before forwarding to https://api.cborg.lbl.gov.
#
# Prerequisites: podman, $CBORG_API_KEY set in the environment.

set -euo pipefail

# ---------------------------------------------------------------------------
# Qdrant
# ---------------------------------------------------------------------------
QDRANT_NAME="qdrant"
QDRANT_DATA="${HOME}/.qdrant"
QDRANT_IMAGE="qdrant/qdrant"

mkdir -p "${QDRANT_DATA}"

if podman container exists "${QDRANT_NAME}" 2>/dev/null; then
  echo "Container '${QDRANT_NAME}' already exists -- starting it."
  podman start "${QDRANT_NAME}"
else
  podman run -d \
    --name "${QDRANT_NAME}" \
    --restart unless-stopped \
    -p 127.0.0.1:6333:6333 \
    -v "${QDRANT_DATA}:/qdrant/storage:z" \
    "${QDRANT_IMAGE}"
fi

echo "Qdrant is running at http://127.0.0.1:6333"

# ---------------------------------------------------------------------------
# CBorg embeddings auth proxy
# ---------------------------------------------------------------------------
PROXY_NAME="cborg-embed-proxy"
PROXY_IMAGE="nginx:alpine"
PROXY_PORT="8929"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_TEMPLATE="${SCRIPT_DIR}/cborg-embed-proxy.conf.template"

if [ -z "${CBORG_API_KEY:-}" ]; then
  echo "WARNING: CBORG_API_KEY is not set -- skipping '${PROXY_NAME}' container." >&2
  echo "         Set CBORG_API_KEY and re-run this script to enable the embeddings proxy."
  exit 0
fi

if podman container exists "${PROXY_NAME}" 2>/dev/null; then
  echo "Container '${PROXY_NAME}' already exists -- starting it."
  podman start "${PROXY_NAME}"
else
  # The official nginx image processes files in /etc/nginx/templates/*.template
  # with envsubst and writes the results to /etc/nginx/conf.d/ at startup.
  podman run -d \
    --name "${PROXY_NAME}" \
    --restart unless-stopped \
    -p 127.0.0.1:${PROXY_PORT}:${PROXY_PORT} \
    -e CBORG_API_KEY="${CBORG_API_KEY}" \
    -v "${CONF_TEMPLATE}:/etc/nginx/templates/cborg-embed-proxy.conf.template:ro,z" \
    "${PROXY_IMAGE}"
fi

echo "CBorg embeddings proxy is running at http://127.0.0.1:${PROXY_PORT}"
echo "Point codebaseIndexEmbedderBaseUrl at http://localhost:${PROXY_PORT}/v1"
