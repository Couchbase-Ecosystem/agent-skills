# Manual sandbox for the Couchbase agent skills (Docker + real Claude Code)

A throwaway Docker environment that runs the **real Claude Code CLI** against a
**live Couchbase MCP server**, so you can poke at the skills the way an end user
actually experiences them — skills auto-trigger by description, MCP tools run
real SQL++/`EXPLAIN`/`INFER`, and answers are grounded in `travel-sample`.

Every run starts from a **wiped `~/.claude`** — no cached skills or config carry
over. Edit a `SKILL.md` locally and re-run; the change is picked up with no
rebuild (the repo is bind-mounted at `/work`).

## Prerequisites

- **Docker** with Compose v2 (`docker compose`). Give it ≥ 3 GB RAM for the
  local Couchbase container.
- **A Claude Code credential.** Preferred: a subscription OAuth token. Generate
  it once on your machine (this is the "click a URL to log in" flow):

  ```bash
  claude setup-token
  ```

  Copy the printed token. (Alternatively use an `ANTHROPIC_API_KEY`.)

## Setup

```bash
cd testing/sandbox
cp .env.example .env
# Edit .env: paste CLAUDE_CODE_OAUTH_TOKEN (or set ANTHROPIC_API_KEY).
# Defaults give you: local cluster (couchbase:enterprise-8.0.1) + local skill copy.
make build
```

## Usage

| Command | What it does |
|---------|--------------|
| `make sandbox` | Fresh interactive `claude` REPL on a local cluster (MCP pre-wired) — poke skills by hand. |
| `make sandbox-remote` | Interactive REPL against a remote/Capella cluster from `.env` (MCP pre-wired). |
| `make sandbox-setup` | Local cluster, **no MCP pre-wired** — exercise the `couchbase-mcp-setup` skill end-to-end. |
| `make sandbox-setup-remote` | Same, but targeting Capella — test the Capella setup path. |
| `make sandbox-setup-cold` | Like `sandbox-setup` but **no `CB_*` in the env either** — a true first-time setup. |
| `make smoke` | **Automated** one-per-skill gate (headless `claude -p`) on a local cluster — fast, keep green. See below. |
| `make scenarios` | **Automated** broader curated suite (headless) — `smoke` plus more cases per skill. See below. |
| `make clean` | Tear down containers and drop the cluster volume. |

> **Testing the *setup* skill.** The plain `sandbox` target **pre-wires** the
> MCP server (so the querying/optimizer skills work immediately) — which skips the
> `couchbase-mcp-setup` flow. The `*-setup` targets launch with **no** server
> connected (`claude mcp list` is empty), the state that skill expects: ask
> *"Set up the Couchbase MCP server"* and watch it drive `claude mcp add` and verify.
> For the **local** target the bundled cluster is provisioned and reachable at
> `couchbase://couchbase` (db creds are pre-set in the env, like a plugin install).
> For the **remote** target, set `CB_*` in `.env` to verify against real Capella, or
> leave them blank to exercise the cold "gather connection details" path. After the
> skill registers the server you may need `/mcp` (or to restart the REPL) to load it.
>
> **`make sandbox-setup-cold`** goes one step further: the bundled cluster is still
> provisioned, but **all `CB_*` are stripped from the session env** before the REPL
> starts — so `env | grep CB_` is empty and the agent has *no* connection string,
> creds, or server to fall back on. It must drive the entire flow from scratch, like
> a brand-new user. The entrypoint banner prints the local cluster's coordinates
> (connection string + db user/password) so you, the human, can answer the skill's
> questions — that represents what you'd already know about your own cluster. (For a
> cold *Capella* run, just use `sandbox-setup-remote` with a blank `.env`.)

**Which cluster you hit is decided by the target, not by your shell.** `sandbox`
always uses the bundled local cluster; `sandbox-remote` uses the `CB_*` in `.env`.
The harness never reads `CB_*` from your shell environment, so an exported
`CB_CONNECTION_STRING` (e.g. a Capella URL in `~/.zshrc`) cannot leak in.

`./run.sh <target>` is an equivalent wrapper if you'd rather not `cd`.

## Automated tests

Two headless targets drive the **real** `claude -p` CLI across curated eval cases
and score each one. They form a reliability ladder — `smoke ⊆ scenarios ⊆ all`:

| Target | Runs | Use it for |
|--------|------|------------|
| `make smoke` | one case per skill (`"smoke": true`) | the always-green gate — fast, run it often / in CI |
| `make scenarios` | `smoke` **+** every `"scenario": true` case | broader coverage while iterating on a skill |

Each case checks two things:

1. **the right skill auto-triggered** — `run-tests.py` parses the stream-json for
   a `Skill` tool_use and matches it against the case's `expect_skill`, and
2. **the answer is reasonable** — expect/reject substring scoring, with the
   querying cases also asserting the expected MCP tool actually ran (`expect_tools`).

Both run in **two phases**, each putting the skill in its meaningful environment
(the same split as `sandbox` vs `sandbox-setup`):

- **MCP pre-wired** — `couchbase-data-modeling`, `couchbase-natural-language-querying`,
  `couchbase-query-optimizer`, so the query skills hit the live `travel-sample` cluster.
- **No MCP pre-wired** — `couchbase-mcp-setup`, so it actually drives the setup flow
  (registering the server, choosing the `couchbase://` scheme, read-only mode) rather
  than just observing an already-connected server.

The cases live as `"smoke"` / `"scenario"` entries in `testing/<skill>/evals/evals.json`,
so the case format stays single-sourced with the model-only `tools/run-evals.py`.
`run-tests.py` prints `PASS`/`FAIL` per case and exits non-zero if any fail; it uses
real OAuth-token inference (~4 `claude -p` calls for `smoke`, ~12 for `scenarios`).

> **Growing the suite.** Add a case to `evals.json`, run it ad-hoc against the
> harness while you tune its assertions (`HARNESS_TEST_ARGS="--skill <name> --case
> <substr>"`), then promote it: `"scenario": true` once it passes reliably, and
> `"smoke": true` for the one broad case per skill that guards the gate. Cases that
> assert `expect_skill` need a prompt that clearly sits in that skill's domain —
> imperative/advisory framing triggers; vague conceptual questions often don't.

## How it works

- **Auth** flows in from `.env` (OAuth token preferred; if set, the API key is
  ignored). The interactive REPL authenticates from a `.credentials.json` that the
  entrypoint seeds from your token — so the sandbox **never prompts for a manual
  login**. The config dir is still wiped every run; only auth + onboarding state
  are re-seeded. (If you ever do get an auth error, your token expired — re-run
  `claude setup-token` and update `.env`.)
- **Skills (local mode, default):** `scripts/install-skills.sh` copies
  `/work/skills/<name>/` (with `references/`) into `~/.claude/skills/` so they
  auto-trigger. **GitHub mode** (`SKILL_INSTALL_MODE=github`) installs the
  published plugin from the marketplace instead.
- **MCP (local mode):** `scripts/mcp-config.gen.sh` renders the repo's
  `mcp.json` into an absolute-path `.mcp.json` with `CB_*` resolved, passed via
  `claude --mcp-config … --strict-mcp-config` (the `--strict` flag makes Claude
  use *only* this file — no host/project `.mcp.json` can leak in). In GitHub mode
  the plugin supplies the MCP server. The `*-setup` targets set
  `HARNESS_PREWIRE_MCP=0`, which **skips** this step so the `couchbase-mcp-setup`
  skill can register the server itself.
- **Cluster:** in local mode the entrypoint **fixes** the cluster coordinates
  (`couchbase://couchbase`, db user `tester`), overriding any inherited `CB_*`,
  and `couchbase-init.sh` provisions the `couchbase/server` container over REST
  and loads `travel-sample`. In remote mode the local container is skipped and
  the `CB_*` from `.env` are used as-is. Cluster config is sourced only from
  `.env` + the harness — never interpolated from your host shell.
- **Permissions:** the container runs as the non-root `node` user (Claude Code
  refuses `--dangerously-skip-permissions` as root) with
  `claude --dangerously-skip-permissions` (safe — throwaway container, read-only
  cluster).
- **Clean room:** the entrypoint scrubs inherited telemetry config
  (`OTEL_*`, `CLAUDE_CODE_ENABLE_TELEMETRY`) so a corporate observability setup
  on your host can't trip Claude Code's "managed settings require approval" gate.

## Known caveats

- **Community vs Enterprise.** The default image is `couchbase:enterprise-8.0.1`.
  Community Edition is license-clean and also loads `travel-sample`, but the
  **query Index Advisor is EE-only**, so optimizer recommendations that rely on it
  won't appear on a Community cluster. Override `CB_IMAGE` in `.env` to switch.
- **GitHub-mode plugin commands.** The non-interactive `claude plugin ...`
  syntax in `install-skills.sh` may vary by CLI version — confirm with
  `claude plugin --help` if GitHub mode fails. Local mode is the primary path.
- **Skill-trigger detection (`make smoke`).** `run-tests.py` infers skill
  activation from a `Skill` tool_use in the stream. If a CLI update changes that
  event shape, the trigger check can mis-fire — run `HARNESS_SHOW_STREAM=1 make
  smoke` to dump the raw stream and adjust `skill_from_tool_use` accordingly.
