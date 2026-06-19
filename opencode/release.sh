#!/usr/bin/env bash
# release.sh -- Build custom opencode binaries incorporating the cborg LiteLLM
# patches and publish them as a GitHub release on awschmeder/opencode.
#
# Targets: darwin-arm64, darwin-x64, linux-arm64, linux-x64
#
# Usage:
#   ./release.sh                  # auto-derive version from upstream npm
#   OPENCODE_VERSION=1.15.5+cborg.20250620 ./release.sh
#
# Required env:
#   gh CLI authenticated (gh auth login) with repo + workflow scopes
#
# Optional env:
#   OPENCODE_VERSION  -- override the full version string
#   BUILD_DIR         -- path to the build-opencode checkout (default: ./build-opencode)
#   SKIP_CLONE        -- set to 1 to skip re-cloning and re-patching (use existing BUILD_DIR)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build-opencode}"
GH_REPO="awschmeder/opencode"

# -- Version derivation -------------------------------------------------------
# If not explicitly set, fetch the latest upstream version from npm and append
# a +cborg.<date> suffix so the release is clearly distinguishable from the
# official opencode releases.
if [[ -z "${OPENCODE_VERSION:-}" ]]; then
  echo "==> Fetching upstream version from npm..."
  UPSTREAM_VERSION="$(curl -fsSL https://registry.npmjs.org/opencode-ai/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])")"
  if [[ -z "$UPSTREAM_VERSION" ]]; then
    echo "ERROR: could not fetch upstream version from npm. Set OPENCODE_VERSION manually." >&2
    exit 1
  fi
  DATE_SUFFIX="$(date -u +%Y%m%d)"
  OPENCODE_VERSION="${UPSTREAM_VERSION}+litellm.${DATE_SUFFIX}"
fi

echo "==> Building opencode version: ${OPENCODE_VERSION}"
echo "==> Release repo:              ${GH_REPO}"
echo "==> Build dir:                 ${BUILD_DIR}"

# -- Prerequisites check ------------------------------------------------------
for cmd in bun gh git curl python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

# -- Clone / update the repo --------------------------------------------------
if [[ "${SKIP_CLONE:-0}" != "1" ]]; then
  if [[ ! -d "$BUILD_DIR/.git" ]]; then
    echo "==> Cloning anomalyco/opencode..."
    git clone https://github.com/anomalyco/opencode.git "$BUILD_DIR"
  fi

  echo "==> Fetching upstream PR #14468 (balcsida LiteLLM provider)..."
  git -C "$BUILD_DIR" fetch origin pull/14468/head:_pr14468_head
  git -C "$BUILD_DIR" checkout --detach _pr14468_head

  echo "==> Fetching cborg patch branches from awschmeder/opencode..."
  FORK_URL="https://github.com/awschmeder/opencode.git"

  BACKFILL_SHA="$(git -C "$BUILD_DIR" ls-remote "$FORK_URL" \
    litellm-backfill-discovered-cost | cut -f1)"
  CACHEWRITE_SHA="$(git -C "$BUILD_DIR" ls-remote "$FORK_URL" \
    litellm-cache-write-tokens | cut -f1)"

  if [[ -z "$BACKFILL_SHA" || -z "$CACHEWRITE_SHA" ]]; then
    echo "ERROR: could not resolve patch branch SHAs from ${FORK_URL}" >&2
    exit 1
  fi

  git -C "$BUILD_DIR" fetch "$FORK_URL" \
    litellm-backfill-discovered-cost \
    litellm-cache-write-tokens

  echo "==> Cherry-picking cost/limit backfill commit: ${BACKFILL_SHA:0:12}"
  git -C "$BUILD_DIR" cherry-pick "$BACKFILL_SHA"

  echo "==> Cherry-picking cache-write token commit:   ${CACHEWRITE_SHA:0:12}"
  git -C "$BUILD_DIR" cherry-pick "$CACHEWRITE_SHA"
fi

# -- Install dependencies -----------------------------------------------------
echo "==> Installing dependencies..."
bun install --cwd "$BUILD_DIR"

# -- Patch build.ts to restrict targets ---------------------------------------
# We do NOT set OPENCODE_RELEASE=1 so the upstream gh release upload block
# never runs. We handle packaging and upload ourselves below.
BUILD_SCRIPT="${BUILD_DIR}/packages/opencode/script/build.ts"
BACKUP="${BUILD_SCRIPT}.cborg.bak"
cp -f "$BUILD_SCRIPT" "$BACKUP"

restore_build_script() {
  if [[ -f "$BACKUP" ]]; then
    cp -f "$BACKUP" "$BUILD_SCRIPT"
    rm -f "$BACKUP"
    echo "==> Restored build.ts"
  fi
}
trap restore_build_script EXIT

echo "==> Patching build.ts (restrict to 4 cborg target platforms)..."
python3 - "$BUILD_SCRIPT" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

# Replace allTargets with only the four cborg platforms.
targets_replacement = '''const allTargets: {
  os: string
  arch: "arm64" | "x64"
  abi?: "musl"
  avx2?: false
}[] = [
  { os: "darwin", arch: "arm64" },
  { os: "darwin", arch: "x64" },
  { os: "linux", arch: "arm64" },
  { os: "linux", arch: "x64" },
]'''

patched = re.sub(
    r'const allTargets:.*?\]\s*(?=\n)',
    targets_replacement,
    content,
    count=1,
    flags=re.DOTALL,
)
if patched == content:
    print("ERROR: allTargets pattern not found in build.ts", file=sys.stderr)
    sys.exit(1)

with open(path, 'w') as f:
    f.write(patched)

print("build.ts patched successfully")
PYEOF

# -- Build --------------------------------------------------------------------
echo "==> Building binaries (darwin-arm64, darwin-x64, linux-arm64, linux-x64)..."

# Export version so Script.version picks it up. Do NOT set OPENCODE_RELEASE --
# that would trigger the upstream gh release upload which targets the wrong repo.
export OPENCODE_VERSION

bun run --cwd "${BUILD_DIR}/packages/opencode" build

restore_build_script
trap - EXIT

# -- Package archives ---------------------------------------------------------
echo "==> Packaging release archives..."
RELEASE_DIR="${SCRIPT_DIR}/release-artifacts"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

DIST_DIR="${BUILD_DIR}/packages/opencode/dist"

for target_dir in "${DIST_DIR}"/*/; do
  [[ -d "$target_dir" ]] || continue
  name="$(basename "$target_dir")"
  bin_dir="${target_dir}bin"
  [[ -d "$bin_dir" ]] || continue

  case "$name" in
    *linux*)
      archive="${RELEASE_DIR}/${name}.tar.gz"
      tar -czf "$archive" -C "$bin_dir" .
      echo "  packaged: $(basename "$archive")"
      ;;
    *darwin*)
      archive="${RELEASE_DIR}/${name}.zip"
      (cd "$bin_dir" && zip -r "$archive" .)
      echo "  packaged: $(basename "$archive")"
      ;;
    *)
      echo "  skipping: $name"
      ;;
  esac
done

if [[ -z "$(ls -A "$RELEASE_DIR" 2>/dev/null)" ]]; then
  echo "ERROR: no release archives found. Check that the build produced output in ${DIST_DIR}" >&2
  exit 1
fi

# -- Create GitHub release ----------------------------------------------------
TAG="v${OPENCODE_VERSION}"
UPSTREAM_BASE="${OPENCODE_VERSION%%+*}"

echo "==> Creating GitHub release ${TAG} on ${GH_REPO}..."

RELEASE_NOTES="## opencode ${OPENCODE_VERSION} (litellm build)

This is a custom build of [opencode](https://github.com/anomalyco/opencode) incorporating:

- **[PR #14468](https://github.com/anomalyco/opencode/pull/14468)** -- LiteLLM provider with auto model discovery (balcsida)
- **[awschmeder/opencode#2](https://github.com/awschmeder/opencode/pull/2)** -- Backfill discovered LiteLLM cost/limit for config-declared models
- **[awschmeder/opencode#3](https://github.com/awschmeder/opencode/pull/3)** -- Extract LiteLLM cache write tokens via MetadataExtractor

Based on upstream opencode \`${UPSTREAM_BASE}\`.

### Platforms
| File | Platform |
|------|----------|
| \`opencode-darwin-arm64.zip\` | macOS Apple Silicon |
| \`opencode-darwin-x64.zip\` | macOS Intel |
| \`opencode-linux-arm64.tar.gz\` | Linux ARM64 |
| \`opencode-linux-x64.tar.gz\` | Linux x86_64 |

### Install (macOS Apple Silicon)
\`\`\`bash
curl -L https://github.com/${GH_REPO}/releases/download/${TAG}/opencode-darwin-arm64.zip -o opencode.zip
unzip opencode.zip
sudo install -m 755 opencode /usr/local/bin/opencode
sudo codesign --force --sign - /usr/local/bin/opencode
\`\`\`

### Install (Linux x86_64)
\`\`\`bash
curl -L https://github.com/${GH_REPO}/releases/download/${TAG}/opencode-linux-x64.tar.gz | tar -xz
sudo install -m 755 opencode /usr/local/bin/opencode
\`\`\`"

# Create the versioned release and mark it as the repo's latest release.
gh release create "$TAG" \
  --repo "$GH_REPO" \
  --title "opencode ${OPENCODE_VERSION} (litellm)" \
  --notes "$RELEASE_NOTES" \
  --latest \
  "$RELEASE_DIR"/*.tar.gz \
  "$RELEASE_DIR"/*.zip

# Move the floating 'latest' tag/release so users can always download
# from a stable URL: .../releases/download/latest/opencode-darwin-arm64.zip
echo "==> Updating floating 'latest' release..."
gh release delete latest --repo "$GH_REPO" --yes 2>/dev/null || true
git -C "$BUILD_DIR" tag -f latest
git -C "$BUILD_DIR" push "https://github.com/${GH_REPO}.git" refs/tags/latest --force

gh release create latest \
  --repo "$GH_REPO" \
  --title "opencode latest (litellm) -- ${OPENCODE_VERSION}" \
  --notes "Floating pointer to the most recent litellm build. Currently \`${TAG}\`.

${RELEASE_NOTES}" \
  --latest=false \
  "$RELEASE_DIR"/*.tar.gz \
  "$RELEASE_DIR"/*.zip

echo ""
echo "==> Versioned release: https://github.com/${GH_REPO}/releases/tag/${TAG}"
echo "==> Latest release:    https://github.com/${GH_REPO}/releases/tag/latest"
echo "==> Done."
