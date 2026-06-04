# Zoo Code Configuration

Configuration and setup scripts for [Zoo Code](https://github.com/zoocode) (VS Code fork) with CBorg models.

## Setup

Run `make` to generate `zoo-code-settings.json`, which can be imported into Zoo Code via
**Zoo Code > Settings > About Zoo Code > Manage Settings > Import**.

Requirements:

- `CBORG_API_KEY` environment variable must be set
- `jq` and `envsubst` must be installed

Optional providers are included automatically when their credentials are detected:

- `AMSC_I2_API_KEY` -- American Science Cloud (AmSC) models
- GCP credentials -- Vertex AI / Gemini models. Credentials are loaded from the first of these
  locations found:
  1. `~/.zoo/application_default_credentials.json`
  2. `~/.roo/application_default_credentials.json` (fallback)
  3. `GOOGLE_APPLICATION_CREDENTIALS` environment variable (path or JSON)
  4. `~/.gcloud/application_default_credentials.json`

## Codebase Indexing (Qdrant)

> **Advanced users only.** Codebase indexing requires Docker or Podman to be installed and
> running. It is not needed for basic chat or autocomplete functionality.

When `podman` is detected during `make`, you will be prompted to enable codebase indexing.
If enabled, Zoo Code uses a local [Qdrant](https://qdrant.tech/) vector database to index
your codebase for context-aware completions.

Before indexing, start Qdrant and the local embeddings proxy:

```bash
CBORG_API_KEY=<your-key> ./start-qdrant.sh
```

The embeddings proxy is a local nginx instance that injects your `CBORG_API_KEY` into requests,
since Zoo Code's openai-compatible embedder mode has no API key field.
