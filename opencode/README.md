# opencode (cborg/LiteLLM build)

A custom build of [opencode](https://github.com/anomalyco/opencode) with LiteLLM provider support
and accurate cost tracking for CBorg API users.

## What is included

This build incorporates the following patches on top of the upstream opencode codebase:

| Patch | Description |
|-------|-------------|
| [PR #14468](https://github.com/anomalyco/opencode/pull/14468) | LiteLLM provider with auto model discovery |
| [awschmeder/opencode#2](https://github.com/awschmeder/opencode/pull/2) | Backfill discovered cost/limit for config-declared models |
| [awschmeder/opencode#3](https://github.com/awschmeder/opencode/pull/3) | Extract cache write tokens via MetadataExtractor for accurate cost tracking |

---

## Option 1 -- Download a pre-compiled binary

Pre-compiled binaries are published to
[awschmeder/opencode releases](https://github.com/awschmeder/opencode/releases/tag/latest).

### macOS (Apple Silicon -- arm64)

```bash
curl -L https://github.com/awschmeder/opencode/releases/download/latest/opencode-darwin-arm64.zip \
  -o opencode.zip
unzip opencode.zip
sudo install -m 755 opencode /usr/local/bin/opencode
# Re-sign the binary after copying (required on macOS)
sudo codesign --force --sign - /usr/local/bin/opencode
```

### macOS (Intel -- x64)

```bash
curl -L https://github.com/awschmeder/opencode/releases/download/latest/opencode-darwin-x64.zip \
  -o opencode.zip
unzip opencode.zip
sudo install -m 755 opencode /usr/local/bin/opencode
sudo codesign --force --sign - /usr/local/bin/opencode
```

### Linux (x86_64)

```bash
curl -L https://github.com/awschmeder/opencode/releases/download/latest/opencode-linux-x64.tar.gz \
  | tar -xz
sudo install -m 755 opencode /usr/local/bin/opencode
```

### Linux (ARM64)

```bash
curl -L https://github.com/awschmeder/opencode/releases/download/latest/opencode-linux-arm64.tar.gz \
  | tar -xz
sudo install -m 755 opencode /usr/local/bin/opencode
```

### Verify the installation

```bash
opencode --version
```

---

## Option 2 -- Build from source

### Prerequisites

- [bun](https://bun.sh) (installed automatically if missing)
- `git`
- macOS or Linux

### Build and install

```bash
# Clone this repo
git clone https://github.com/lbnl-science-it/cborg-client.git
cd cborg-client/opencode

# Build for the current platform and install to /usr/local/bin
make build
make install
```

`make build` will:
1. Clone `anomalyco/opencode` into `./build-opencode/`
2. Check out the head of upstream PR #14468 (LiteLLM provider)
3. Cherry-pick the two cborg cost-tracking patches
4. Install dependencies with `bun install`
5. Compile a native binary for the current OS and architecture

The resulting binary is placed at `./opencode` and `make install` copies it to `/usr/local/bin/opencode`.

On macOS, re-sign the installed binary if you see a SIGKILL on launch:

```bash
sudo codesign --force --sign - /usr/local/bin/opencode
```

### Other make targets

```bash
make clean    # remove ./build-opencode/ and ./opencode
```

---

## Configuration

Copy the included `opencode.json` to your opencode config directory:

```bash
mkdir -p ~/.config/opencode
cp opencode.json ~/.config/opencode/opencode.json
```

Set your CBorg API key:

```bash
export CBORG_API_KEY=your-api-key-here
```

The config points opencode at the CBorg LiteLLM proxy (`https://api.cborg.lbl.gov/v1`) and
pre-declares the following models:

| Model ID | Display name |
|----------|-------------|
| `cborg-coder-fast` | CBorg Coder Fast |
| `cborg-coder` | CBorg Coder |
| `gemini-flash-lite` | Gemini Flash Lite ($) |
| `gemini-flash` | Gemini Flash ($$) |
| `gemini-pro-high` | Gemini Pro ($$$) |
| `gpt-codex` | GPT Codex ($$) |
| `claude-sonnet-high` | Claude Sonnet ($$$) |
| `claude-opus-high` | Claude Opus ($$$$) |

Additional models available on the proxy are discovered automatically at startup.

---

## Publishing a new release

Maintainers can publish a new release with:

```bash
./release.sh
```

This builds all four platform binaries, creates a versioned GitHub release
(e.g. `v1.15.5+litellm.20250620`), and updates the floating `latest` release.

```bash
# Override the version string
OPENCODE_VERSION=1.15.5+litellm.20250620 ./release.sh

# Skip re-cloning if build-opencode/ already exists and is patched
SKIP_CLONE=1 ./release.sh
```
