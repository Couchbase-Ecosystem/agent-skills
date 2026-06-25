# Server configuration reference

The server's own knobs — every `CB_*` env var, authentication modes, transport, and version/package facts. (For *how each client registers the server*, see [`client-setup.md`](client-setup.md). For read-only / disabling / confirmation, see [`safety.md`](safety.md).)

- [Environment variables](#environment-variables)
- [Authentication](#authentication)
- [Transport](#transport)
- [Requirements & packages](#requirements--packages)

## Environment variables

Every var has a CLI-arg equivalent; **CLI args override env vars**. Read-only/disable/confirm vars are detailed in [`safety.md`](safety.md).

| Env var | CLI arg | Default | Purpose |
|---------|---------|---------|---------|
| `CB_CONNECTION_STRING` | `--connection-string` | **required** | `couchbases://…` (TLS, Capella) or `couchbase://…` (non-TLS, local) |
| `CB_USERNAME` | `--username` | required (or mTLS) | basic-auth user |
| `CB_PASSWORD` | `--password` | required (or mTLS) | basic-auth password |
| `CB_CLIENT_CERT_PATH` | `--client-cert-path` | required for mTLS | client certificate |
| `CB_CLIENT_KEY_PATH` | `--client-key-path` | required for mTLS | client key |
| `CB_CA_CERT_PATH` | `--ca-cert-path` | — | server root CA for self-signed / untrusted TLS. **Not needed for Capella** |
| `CB_MCP_READ_ONLY_MODE` | `--read-only-mode` | `true` | block all writes (KV + query) |
| `CB_MCP_TRANSPORT` | `--transport` | `stdio` | `stdio` · `http` · `sse` (deprecated) |
| `CB_MCP_HOST` | `--host` | `127.0.0.1` | bind host (http/sse only) |
| `CB_MCP_PORT` | `--port` | `8000` | bind port (http/sse only) |
| `CB_MCP_DISABLED_TOOLS` | `--disabled-tools` | none | tools to drop — CSV or file path |
| `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` | `--confirmation-required-tools` | none | tools needing confirmation — CSV or file path |

> The last row's names are verified against the server source. The upstream docs site lists `CB_MCP_CONFIRMATION_REQUIRED` / `--confirmation-required` (no `_TOOLS`) — that is a **docs-site error**; the server reads the `_TOOLS` forms. Do not "correct" it back.

## Authentication

Pick **one**:
- **Basic** — `CB_USERNAME` + `CB_PASSWORD`.
- **mTLS** — `CB_CLIENT_CERT_PATH` + `CB_CLIENT_KEY_PATH`. If both basic and mTLS are set, **mTLS wins**.

TLS server-cert validation:
- **Capella** → bundled root CA is used automatically; leave `CB_CA_CERT_PATH` unset.
- **Self-signed / untrusted** → set `CB_CA_CERT_PATH` to the CA root cert.

## Transport

`stdio` (default) — coding agents launch the server directly. Use it unless you need a long-lived server shared by multiple clients, which is `http` (Streamable HTTP; `sse` is deprecated) — set via the `CB_MCP_TRANSPORT`/`CB_MCP_HOST`/`CB_MCP_PORT` rows above. For the `http` run command, endpoint, and client URL registration, see [`client-setup.md`](client-setup.md).

## Requirements & packages

| | |
|---|---|
| Python | 3.10+ (only if running via `uvx`/source; not needed for Docker) |
| Couchbase Server | 7.2+ (8.0+ required for `list_indexes`) |
| Runtime | `uv`/`uvx` **or** Docker |
| PyPI package | `couchbase-mcp-server` |
| Docker image | `couchbaseecosystem/mcp-server-couchbase` (also `mcp/couchbase` on the Docker MCP catalog) |
| Version check | `uvx couchbase-mcp-server --version` |

> **First-launch latency:** on a cold cache `uvx` resolves the version range and downloads the package before the server starts, so the first launch (or the first after a cache prune) can be slow enough to miss the client's MCP startup window — the tools then appear only on a later restart. For deterministic startups, `uv tool install "couchbase-mcp-server>=0.8.0,<0.9.0"` or pre-warm with the version-check command above, and/or launch with a larger `MCP_TIMEOUT` (ms). See SKILL.md → Troubleshooting.

Unsupported services (no tools): Analytics, Sync Gateway, Couchbase Lite, Capella AI Services.
