---
name: review-skill
description: >-
  Review a proposed Couchbase Agent Skill for structural validity and content
  quality before publishing. Runs the skill validator, then applies a manual
  content-review checklist tuned to Couchbase access patterns. Use when a user
  wants to review, validate, or quality-check a skill.
license: Apache-2.0
---

# Review Skill (meta-tool)

> **Skeleton — to be fleshed out (see project Task 13).** This establishes the
> structure; the full LLM-scoring workflow is not yet implemented.

## Workflow

1. **Structural validation.** Run `./tools/validate-skills.sh` and interpret
   failures (blocking) vs warnings (advisory).
2. **Manual content review.** Check the skill against the Couchbase checklist below.
3. **Report.** Summarize blocking issues, then advisory improvements, prioritized.

## Couchbase content checklist

- **Access pattern fit:** Does the skill choose the right Couchbase access path —
  KV (by key) vs SQL++ (query) vs Search Service (FTS/vector) — and explain why?
- **MCP grounding:** Does it call the right MCP tools to ground work in the live
  cluster (`get_schema_for_collection`, `list_indexes`, `explain_sql_plus_plus_query`,
  `run_sql_plus_plus_query`, `get_index_advisor_recommendations`)?
- **Read-only safety:** Are writes/DDL gated behind explicit user approval?
- **Terminology:** SQL++/GSI/Bucket-Scope-Collection/Search Service/Capella — no language that references other Databases (`$`-operators, "Atlas", "aggregation pipeline").
- **Scope gating:** Clear when-to-use, and correct hand-offs to sibling skills.
- **Examples & edge cases:** Real, runnable SQL++/examples; covers common failure modes.

## TODO

- Add optional LLM-judge scoring across dimensions (correctness, scope, clarity).
- Wire prerequisite detection and state persistence.
