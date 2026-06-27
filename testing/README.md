# Testing

Per-skill evaluation suites live under `testing/<skill-name>/evals/evals.json`.

Each suite defines prompts and assertions used to check that a skill triggers
correctly and produces valid Couchbase output (SQL++, index/DDL, search-index
definitions). Copy `testing/_template/evals/evals.json` to start a new suite.

The same suites feed two runners:

- **`tools/run-evals.py`** — model-only scoring (Tier 2). Sends each `SKILL.md` +
  case `input` to a model and checks the response. Fast, no cluster. Documented below.
- **The sandbox** ([`testing/sandbox/`](./sandbox/README.md)) — the real Claude Code
  CLI against a live Couchbase cluster, so it can verify **skill triggering** and
  **real MCP tool calls** (Tier 3). Runs the `smoke` / `scenario` cases —
  see [Real-harness tests](#real-harness-tests-the-sandbox).

## Schema

```jsonc
{
  "skill": "couchbase-<skill-name>",
  "cases": [
    {
      "name": "short description of the scenario",
      "input": "the user prompt",
      "expect": ["substrings that MUST appear in the response"],
      "reject": ["substrings that must NOT appear"],
      "threshold": 1,           // optional: min count of `expect` matches required
      "tier": 2,                // optional: 2 = model-only (default); 3 = needs the real harness/cluster

      // ── optional, consumed only by the real-harness sandbox (testing/sandbox) ──
      "smoke": true,            // include in `make smoke` (the one-per-skill gate)
      "scenario": true,         // include in `make scenarios` (broader curated suite)
      "expect_skill": "couchbase-<skill-name>",    // this skill must auto-trigger
      "expect_tools": ["run_sql_plus_plus_query"]  // these MCP tools must be called
    }
  ]
}
```

You don't need both flags: `make scenarios` runs every case flagged `smoke` **or**
`scenario`, so a `smoke` case is automatically part of the scenario run.
`expect_skill` / `expect_tools` describe events the model-only runner can't
observe, so they only take effect in the sandbox.

## Running

The runner is `tools/run-evals.py` (pure standard library — no install needed).

```bash
# Validate suite schema + list cases — no network, no API key (default mode).
python3 tools/run-evals.py --dry-run

# Run the behavioral evals against the model (Tier 2). Needs an API key.
# Provider auto-detects from whichever key is set; force it with --provider.
ANTHROPIC_API_KEY=sk-ant-... python3 tools/run-evals.py --execute
OPENAI_API_KEY=sk-...        python3 tools/run-evals.py --execute --skill couchbase-natural-language-querying
python3 tools/run-evals.py --execute --provider openai --model gpt-4o
```

> These skills target Claude harnesses, so scoring against an OpenAI model is a useful **proxy** (catches gross issues) rather than a production-fidelity test.

### Tiers

- **Structural** — `./tools/validate-skills.sh`: frontmatter/links/sizes. Free, deterministic; runs on every PR.
- **Schema (`--dry-run`)** — validates each `evals.json` shape (incl. `threshold ≤ expect` count). Free, deterministic; also runs on every PR.
- **Tier 2 (`--execute`)** — sends the skill's `SKILL.md` as the system prompt + each case `input` to the model, then checks the response contains ≥ `threshold` of `expect` and none of `reject`. Provider auto-detects from `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` (or `--provider`). Costs tokens and is **non-deterministic**, so each case is **retried up to 3×** and passes on the first attempt that scores — only a consistent miss across all attempts fails (attempt 1 runs at temperature 0, retries resample slightly hotter). A failure is a quality signal, not a merge blocker.
- **Tier 3 (`tier: 3` cases)** — live MCP/cluster grounding (real queries / `EXPLAIN`) and skill **triggering**. The model-only `run-evals.py` can't observe these — it only sends `SKILL.md` — so `--execute` **skips tier 3 by default** (`--tier 3` includes them, but they won't meaningfully pass there). Run them for real with the **sandbox** (`make smoke` / `make scenarios`); see [Real-harness tests](#real-harness-tests-the-sandbox) below.

## Real-harness tests (the sandbox)

`tools/run-evals.py` only sends each `SKILL.md` to a model, so it checks a skill's
*guidance* but never whether the skill **auto-triggers** or calls the right **MCP
tools** against a live cluster. The sandbox in [`testing/sandbox/`](./sandbox/README.md)
does both: it runs the real Claude Code CLI with the skills installed and the
Couchbase MCP server wired to a `travel-sample` cluster, then scores each case on
triggering (`expect_skill`), tool calls (`expect_tools`), and the `expect` /
`reject` substrings. It also offers a **manual interactive REPL** for poking at the
skills by hand.

Two automated targets run the curated cases from the same `evals.json` files:

| Command (from `testing/sandbox/`) | Runs |
|-----------------------------------|------|
| `make smoke` | the one-per-skill gate (`"smoke": true`) — fast, keep green |
| `make scenarios` | the broader curated suite (`smoke` + `"scenario": true`) |

**See [`testing/sandbox/README.md`](./sandbox/README.md)** for prerequisites
(Docker + a Claude token), setup, the manual REPL, and the full target list.
