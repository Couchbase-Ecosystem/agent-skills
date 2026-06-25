---
name: couchbase-skill-name
description: >-
  One or two sentences: what this skill does and WHEN an agent should invoke it.
  Be specific about triggers (e.g. "Use when the user asks to optimize a SQL++
  query or diagnose a slow query / missing index").
license: Apache-2.0
---

# <Skill Title>

> Template. Copy this directory to `skills/couchbase-<name>/`, rename, and fill in.
> Keep `SKILL.md` focused; push depth into `references/`.

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

> **House style — structure each reference by its access pattern (decided per doc):**
> a *choice-shaped* doc (the reader has a situation and must pick one path) ends with a terse
> `## Quick decision tree` of `- **condition?** → action` lines; keep *symptom→fix* and *catalog*
> content as **lookup tables**; use a `- [ ]` **checklist** for *verification*. Don't add a tree
> that merely restates a table or a multi-factor rule already on the page.
