# Access safety: read-only, disabling, confirmation

How to constrain what the agent can do. **RBAC is the only authoritative control** — read-only mode, disabling, and confirmation are defense-in-depth that an LLM (or SQL++ DML) can route around. For credential creation see [`capella-setup.md`](capella-setup.md) / [`local-setup.md`](local-setup.md); tool names are in [`tools.md`](tools.md).

- [Read-only mode](#read-only-mode) — the default, blocks writes
- [Disabling tools](#disabling-tools) — drop tools entirely
- [Confirmation prompts](#confirmation-prompts) — require approval before a tool runs

## Read-only mode

`CB_MCP_READ_ONLY_MODE=true` is the default in the bundled `mcp.json`. (The server's *own* default is `false` on `1.0+`, so on the `claude mcp add` / direct-config routes **set it explicitly** instead of relying on the default.) Effects of `=true`:
- The 4 KV write tools (`upsert`/`insert`/`replace`/`delete_document_by_id`) are **not loaded** — absent from tool discovery.
- `run_sql_plus_plus_query` stays loaded but **rejects** write DML (INSERT/UPDATE/DELETE/MERGE) and DDL.

To allow writes, set `CB_MCP_READ_ONLY_MODE=false`.

| `READ_ONLY_MODE` | Result |
|---|---|
| `true` | All writes disabled (KV + query) |
| `false` | All writes allowed (KV + query) |

> **`CB_MCP_READ_ONLY_MODE` is the single write switch** — one variable governs both KV and query writes.

## Disabling tools

`CB_MCP_DISABLED_TOOLS` — drop specific tools so they don't load or appear in discovery. CLI: `--disabled-tools`.

Two formats (tool names must match [`tools.md`](tools.md) exactly):
```bash
CB_MCP_DISABLED_TOOLS="upsert_document_by_id, delete_document_by_id"   # CSV, spaces optional
CB_MCP_DISABLED_TOOLS=/path/to/disabled_tools.txt                       # file: one name per line, # = comment
```
In Docker the file must be inside the container at that path.

## Confirmation prompts

`CB_MCP_CONFIRMATION_REQUIRED_TOOLS` — listed tools prompt the user (via MCP [elicitation](https://modelcontextprotocol.io/docs/concepts/elicitation)) before running. CLI: `--confirmation-required-tools`. Same CSV/file formats as disabling.

> **Verified name.** The server reads `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` / `--confirmation-required-tools`. The docs site's `CB_MCP_CONFIRMATION_REQUIRED` / `--confirmation-required` (no `_TOOLS`) is wrong — do not use it.

Gotchas:
- **Silent fallback:** clients without elicitation support run the tool with **no** confirmation.
- **No-op on unloaded tools:** listing a tool that didn't load (disabled, or a write tool under read-only) does nothing.
- **Per-tool, not per-action:** confirming `delete_document_by_id` does **not** catch a delete done via `run_sql_plus_plus_query`.

## Why none of these is a security boundary

`run_sql_plus_plus_query` can perform DML, so it can write data even if the KV write tools are disabled/gated (unless read-only mode blocks query writes). Disabling/confirmation only shape LLM behavior. Enforce real limits with a **least-privilege database user** (RBAC) scoped to the buckets/scopes you want reachable — combine it with read-only mode for two layers.
