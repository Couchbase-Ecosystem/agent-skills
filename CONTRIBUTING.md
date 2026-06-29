# Contributing

## Authoring a skill

Each skill lives in `skills/<skill-name>/` and must contain a `SKILL.md`. Optional supporting files:

```
skills/<skill-name>/
  SKILL.md                 # required — the skill playbook
  references/*.md          # optional — deep-dive reference material loaded on demand
  examples/examples.md     # optional — worked examples (also used by eval suites)
```

Start from this template:

```markdown
---
name: couchbase-skill-name
description: >-
  One or two sentences: what this skill does and WHEN an agent should invoke it.
  Be specific about triggers (e.g. "Use when the user asks to optimize a SQL++
  query or diagnose a slow query / missing index").
license: Apache-2.0
---

# <Skill Title>

## When to use this skill

<Concrete triggers. What's in scope and out of scope. Which sibling skill to
hand off to for out-of-scope requests.>

## Gather context (via the Couchbase MCP server)

<Which MCP tools to call first to ground the work in the live cluster, e.g.
`get_schema_for_collection`, `list_indexes`, `explain_sql_plus_plus_query`,
`run_sql_plus_plus_query`. Treat the cluster as read-only unless the user
approves a write/DDL.>

## Workflow

1. <Step>
2. <Step>

## Guidelines

- Use Couchbase-native terminology (SQL++, GSI, Bucket/Scope/Collection, Search Service, Capella).
- Prefer real-cluster evidence over generic advice.

## References

- `references/<topic>.md` — <what it covers>
```

### `SKILL.md` frontmatter

```yaml
---
name: couchbase-<skill-name>        # must match the directory name
description: >-                      # when to use this skill (drives triggering)
  One or two sentences describing what the skill does and when an agent
  should invoke it.
license: Apache-2.0
---
```

### Conventions

- **MCP-centric.** Skills operate a live cluster through the Couchbase MCP server (`run_sql_plus_plus_query`, `explain_sql_plus_plus_query`, `get_schema_for_collection`, `list_indexes`, `get_index_advisor_recommendations`, KV doc tools, etc.). Prefer grounding advice in the real cluster over generic guidance.
- **Language-agnostic.** Rely on SQL++ and MCP rather than per-language SDK code. (Per-language SDK code-generation lives in a separate effort.)
- **Couchbase-native terminology.** Use Bucket → Scope → Collection, SQL++, GSI, the Search Service, Capella
- **Read-only by default.** Treat the MCP server as read-only (`CB_MCP_READ_ONLY_MODE=true`); require explicit user approval before any write/DDL.
- **Size.** Keep `SKILL.md` focused; push depth into `references/`.

## Validation

```bash
./tools/validate-skills.sh
```

CI runs the same checks (`.github/workflows/validate-skills.yml`).

## Testing

Validate eval-suite schema (free, deterministic, no API key — runs on every PR):

```bash
python3 tools/run-evals.py --dry-run
```

Two runners exercise a skill's behavior — see [`testing/README.md`](./testing/README.md):

- **Model-only evals** (`tools/run-evals.py --execute`) — quick scoring of a skill's
  guidance against a model. Needs an API key; no cluster.
- **The real-harness sandbox** ([`testing/sandbox/`](./testing/sandbox/README.md)) — the
  real Claude Code CLI against a live Couchbase cluster: a manual REPL plus automated
  `make smoke` / `make scenarios` tests that verify skill **triggering** and real
  **MCP tool calls**.

## Reviewing a skill

Use the `tools/review-skill` meta-tool to structurally validate and quality-check a skill before publishing.

## TODOs for maintainers

- Confirm the published **org/repository URL** and update it across the manifests, `README.md`, and `skills/OWNERS.yaml`.
- Confirm a maintainer **contact email** for the plugin manifests if one is desired.
- Assign real **DRIs** in `skills/OWNERS.yaml`.
