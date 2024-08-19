# cborg-client

Client-side utilities for CBorg API Services

`/continue`

Provides a config.json and installer script for using CBorg models with the VS Code "Continue" plugin.

Requires use of the CBorg client-side proxy service.

`/proxy`

This is a client-side reverse proxy service that streamlines use of the CBorg API:

Features:

- Allows multiple applications to share a pool of upstream connections
- Enables seamless compliance with CBorg API policies for rate limiting and parallel connection limits
- Enables low-latency embedding calls to execute in parallel with completion calls
- Queues chat completion calls, only allowing one to process at a time
- Handles client-side request cancellations cleanly, freeing up upstream resources instantly
- Detects when client is on LBL-net or VPN, and switches endpoint automatically to locally-routed address to avoid cloudflare limiting & latency cost
- Automagically injects user API key from environment variable: no need to store API keys in files or applications

