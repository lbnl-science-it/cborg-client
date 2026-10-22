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
# Use the default model from config.toml (cborg-coder-max)
codex

# Switch profiles with --profile
codex --profile cborg-gpt-mini
codex --profile cborg-gpt-large
```

## Profiles

| Profile | Model | Notes |
|---------|-------|-------|
| (none) | `cborg-coder-max` | Default, set in `config.toml` -- free, experimental, 600K context |
| `cborg-gpt-mini` | `gpt-5.4-mini` | Cost-effective, medium reasoning |
| `cborg-gpt-large` | `gpt-5.5` | High reasoning, ~10x cost of mini |
| `cborg-gemini-pro` | `gemini-pro-high` | Gemini Pro via CBorg |
| `cborg-gemini-flash` | `gemini-flash-high` | Gemini Flash via CBorg |
| `openai-gpt-large` | `gpt-5.5` | OpenAI direct (ChatGPT Enterprise) |
| `openai-gpt-mini` | `gpt-5.4-mini` | OpenAI direct (ChatGPT Enterprise) |

## MCP Servers

`config.toml` enables the CBorg-proxied Tavily (web search), Context7 (library docs), and
Valency (scientific literature) MCP servers, authenticated with `CBORG_API_KEY`. Run `/mcp`
inside Codex to confirm they are connected.

See the [CBorg Codex CLI docs](https://cborg.lbl.gov/tools_codex) for full instructions and cost-saving tips.
