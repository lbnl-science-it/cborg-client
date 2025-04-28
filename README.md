# cborg-client

Client-side utilities for CBorg API Services

## VS Code Continue Configuration

`/continue`

Provides a config.json for the Continue plugin, and installer script pre-configured to use CBorg models.

Run `./continue/install-vscode-continue.sh` to start the installation. The script provides three methods of installation: Manual, Standard (Recommended), and Proxy (Advanced).

**Contents:**

- /proxy: Client-side reverse proxy
- /continue: Managed config.json file for VS Code Continue Plugin
- /app: Mac OSX Menu-bar App for Client-side proxy (in development - not working yet)

## cborgproxy.py: Client-side Reverse Proxy Service

This reverse proxy service can simplify application deployment and reduce latency of CBorg API calls while connected to VPN or LBL-net. 

This is for advanced users and is experimental. 

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


