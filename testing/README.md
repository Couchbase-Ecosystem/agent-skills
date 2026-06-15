# Testing

Per-skill evaluation suites live under `testing/<skill-name>/evals/evals.json`.

Each suite defines prompts and assertions used to check that a skill triggers
correctly and produces valid Couchbase output (SQL++, index/DDL, search-index
definitions). Copy `testing/_template/evals/evals.json` to start a new suite.

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
      "tier": 2                 // optional: 2 = model-only (default); 3 = needs the real harness/cluster
    }
  ]
}
```

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
- **Tier 2 (`--execute`)** — sends the skill's `SKILL.md` as the system prompt + each case `input` to the model, then checks the response contains ≥ `threshold` of `expect` and none of `reject`. Provider auto-detects from `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` (or `--provider`). Costs tokens and is **non-deterministic**, so it runs on a **schedule / manual dispatch** (`.github/workflows/evals.yml`) — **not** as a PR gate. A failure is a quality signal, not a merge blocker.
- **Tier 3 (`tier: 3` cases, not yet runnable here)** — cross-skill routing/deferral and live MCP/cluster grounding (running real queries / `EXPLAIN`). These need the real harness (a Couchbase Server / Capella project with `travel-sample` + `CB_*` env), so `--execute` **skips them by default**; pass `--tier 3` to include them (they won't pass in this isolated runner until a real-harness runner exists). Tier 2 only sends `SKILL.md`, so it tests a skill's guidance — not routing or real query execution.
