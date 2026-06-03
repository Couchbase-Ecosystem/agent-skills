# Contributing

## Authoring a skill

Each skill lives in `skills/<skill-name>/` and must contain a `SKILL.md`. Optional supporting files:

```
skills/<skill-name>/
  SKILL.md                 # required — the skill playbook
  references/*.md          # optional — deep-dive reference material loaded on demand
  examples/examples.md     # optional — worked examples (also used by eval suites)
```

Start from the template at [`skills/_template/SKILL.md`](./skills/_template/SKILL.md).

### `SKILL.md` frontmatter

```yaml
---
name: couchbase-<skill-name>        # must match the directory name
description: >-                      # when to use this skill (drives triggering)
  One or two sentences describing what the skill does and when an agent
  should invoke it.
license: Apache-2.0
metadata:
  version: "0.1.0"
---
```

### Conventions

- **MCP-centric.** Skills operate a live cluster through the Couchbase MCP server (`run_sql_plus_plus_query`, `explain_sql_plus_plus_query`, `get_schema_for_collection`, `list_indexes`, `get_index_advisor_recommendations`, KV doc tools, etc.). Prefer grounding advice in the real cluster over generic guidance.
- **Language-agnostic.** Rely on SQL++ and MCP rather than per-language SDK code. (Per-language SDK code-generation lives in a separate effort.)
- **Couchbase-native terminology.** Use Bucket → Scope → Collection, SQL++, GSI, the Search Service, Capella
- **Read-only by default.** Treat the MCP server as read-only (`CB_MCP_READ_ONLY_QUERY_MODE=true`); require explicit user approval before any write/DDL.
- **Size.** Keep `SKILL.md` focused; push depth into `references/`.

## Validation

```bash
./tools/validate-skills.sh
```

CI runs the same checks (`.github/workflows/validate-skills.yml`). Before opening a PR, also run the relevant eval suite under `testing/`.

## Reviewing a skill

Use the `tools/review-skill` meta-tool to structurally validate and quality-check a skill before publishing.

## TODOs for maintainers

- Confirm the published **org/repository URL** and update it across the manifests, `README.md`, and `skills/OWNERS.yaml`.
- Confirm a maintainer **contact email** for the plugin manifests if one is desired.
- Assign real **DRIs** in `skills/OWNERS.yaml`.
