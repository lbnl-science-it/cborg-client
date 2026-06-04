# cborg-client

Client-side utilities for CBorg API Services

**Contents:**

- /zoocode: Configuration and setup for ZooCode (formerly RooCode) with CBorg models
- /app: Mac OSX Menu-bar App for Client-side proxy (in development - not working yet)
- /proxy: Client-side reverse proxy
- /continue: Managed config.json file for VS Code Continue Plugin

## Zoo Code Configuration

`/zoocode`

Provides a `Makefile`-based setup for [ZooCode](https://github.com/zoocode) (a VS Code fork)
pre-configured to use CBorg models. Run `make` inside the `zoocode/` directory to generate a
`zoo-code-settings.json` file that can be imported into Zoo Code.

Optional providers (AmSC, GCP/Vertex AI) are included automatically when credentials are
detected. Codebase indexing via Qdrant is available for advanced users with Docker or Podman
installed.

See [`zoocode/README.md`](zoocode/README.md) for full setup instructions.

## cborgproxy.py: Client-side Reverse Proxy Service

This reverse proxy service can simplify application deployment and reduce latency of CBorg API calls while connected to VPN or LBL-net. 

This is for advanced users and is experimental. 

> **Note:** This app has not been tested recently and is likely not needed for most applications
> today. The CBorg API can be accessed directly using your API key without a local proxy.


### How it works:

The proxy service runs on your local machine, enabling LLM completion requests to be directed to
ports 8001-8003 on localhost. API keys are injected automatically from the $CBORG_API_KEY environment variable.
In addition, the proxy service monitors your key usage (budget) and network connectivity status, automatically
routing traffic to the Cloudflare-based endpoint or the LBLNet-routed endpoint depending on network status.

#### When Client is on Public Internet

```
User Application       CBorg Client Proxy          Cloudflare      CBorg API Server
e.g. VSCode with  ==>  http://localhost:8001  ==>   Tunnel    ==>  https://api.cborg.lbl.gov
     "Continue"
```

#### When Client is on LBL-Net

```
User Application       CBorg Client Proxy          CBorg API Server
e.g. VSCode with  ==>  http://localhost:8001  ==>  https://api-local.cborg.lbl.gov
     "Continue"
```

### Features:

- Detects when client is on LBLNet / VPN, and switches endpoint automatically to locally-routed address to avoid Cloudflare limiting
- Automagically injects user API key from environment variable: no need to store API keys in files or applications
- Allows multiple applications on client system to share a pool of upstream connections
- Enables low-latency embedding calls to execute in parallel with completion calls
- Queues chat completion calls, only allowing one to process at a time
- Periodically monitors and reports key usage and maximum budget

### Instructions:

1. Set your CBorg API key as an environment variable in CBORG_API_KEY.
2. Set the API Base URL in your application to http://localhost:8001
3. Run `./proxy/start-cborg-client-proxy.sh`

The proxy service on port 8001 will automatically inject your API keys, therefore API keys do not need to be stored in the user application.

Use port 8001 for chat completions. Use port 8002 for embeddings, and port 8003 for code completion (fill-in-the-middle). This will enable the different types of requests to execute in parallel.

## VS Code Continue Configuration File

> **Note:** The Continue integration has not been tested recently and the instructions below are
> unlikely to work as written. Proceed with caution.

`/continue/config.json`

Provides a config.json for the Continue plugin, and installer script pre-configured to use CBorg models via the client-side proxy.

Run `./continue/install-vscode-continue.sh` to install the provided config.json file. It will create a symlink from `~/.continue/config.json` to the managed file.

## Menu-bar App

This is still under development.
