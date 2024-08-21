# cborg-client

Client-side utilities for CBorg API Services

## Client-side Reverse Proxy Service

This is a client-side reverse proxy service that streamlines use of the CBorg API.

### Features:

- Allows multiple applications to share a pool of upstream connections
- Enables seamless compliance with CBorg API policies for rate limiting and parallel connection limits
- Enables low-latency embedding calls to execute in parallel with completion calls
- Queues chat completion calls, only allowing one to process at a time
- Handles client-side request cancellations cleanly, freeing up upstream resources instantly
- Detects when client is on LBL-net or VPN, and switches endpoint automatically to locally-routed address to avoid cloudflare limiting & latency cost
- Automagically injects user API key from environment variable: no need to store API keys in files or applications


### How it works:

```

User Application     CBorg Client Proxy        CBorg API Server
e.g. VSCode with ==> http://localhost:8001 ==> https://api.cborg.lbl.gov
     "Continue"
```

### Instructions:

1. Set your CBorg API key as an environment variable in CBORG_API_KEY.
2. Set the API Base URL in your application to http://localhost:8001
3. Run `./proxy/start-cborg-client-proxy.sh`

The proxy service on port 8001 will automatically inject your API keys, therefore API keys do not need to be stored in the user application.

In addition, it will detect when your system is connected to LBL-net (via ethernet, employee wireless or VPN) and automatically switch the endpoint to https://api-local.cborg.lbl.gov.

Use port 8001 for chat completions. Use port 8002 for embeddings, and port 8003 for code completion (fill-in-the-middle).

Parallel requests to the local ports will be sequentially queued. If a client cancels the connection mid-stream the resource will be freed up immediately.


## VS Code Continue Configuration File

`/continue/config.json`

Provides a config.json for the Continue plugin, and installer script pre-configured to use CBorg models via the client-side proxy.

Run `./continue/install-vscode-continue.sh` to install the provided config.json file. It will create a symlink from `~/.continue/config.json` to the managed file.

## Menu-bar App

This is still under development.


