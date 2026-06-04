# CBorg Codex CLI Configuration

Configuration files for [OpenAI Codex CLI](https://github.com/openai/codex) using the CBorg API.

## Setup

1. Copy `config.toml` to `~/.codex/config.toml` (or merge the `[model_providers.cborg]` block into your existing config).
2. Copy the profile files you want to use into `~/.codex/`:

```bash
cp config.toml ~/.codex/config.toml
cp cborg-gpt-mini.config.toml ~/.codex/
cp cborg-gpt-large.config.toml ~/.codex/
cp cborg-gemini-pro.config.toml ~/.codex/
cp cborg-gemini-flash.config.toml ~/.codex/
# Optional: OpenAI direct profiles (requires ChatGPT Enterprise sign-on)
cp openai-gpt-large.config.toml ~/.codex/
cp openai-gpt-mini.config.toml ~/.codex/
```

3. Set your API key:

```bash
export CBORG_API_KEY=<your-key>
```

## Usage

```bash
# Use the default profile (cborg-gpt-mini)
codex

# Switch profiles with --profile
codex --profile cborg-gpt-large
codex --profile cborg-gemini-pro
```

## Profiles

| Profile | Model | Notes |
|---------|-------|-------|
| `cborg-gpt-mini` | `gpt-5.4-mini` | Default -- cost-effective, medium reasoning |
| `cborg-gpt-large` | `gpt-5.5` | High reasoning, ~10x cost of mini |
| `cborg-gemini-pro` | `gemini-pro-high` | Gemini Pro via CBorg |
| `cborg-gemini-flash` | `gemini-flash-high` | Gemini Flash via CBorg |
| `openai-gpt-large` | `gpt-5.5` | OpenAI direct (ChatGPT Enterprise) |
| `openai-gpt-mini` | `gpt-5.4-mini` | OpenAI direct (ChatGPT Enterprise) |

See the [CBorg Codex CLI docs](https://cborg.lbl.gov/tools_codex) for full instructions and cost-saving tips.
