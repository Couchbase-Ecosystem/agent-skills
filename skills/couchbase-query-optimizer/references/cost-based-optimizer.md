# Cost-based optimizer (CBO) & statistics

Why the planner chose a plan, and how to make it choose better. CBO **augments** the rule-based optimizer
where statistics make a better choice possible — it does not replace it. Read this when joins pick the wrong
algorithm/order, or an index isn't used despite existing.

## Contents
- [Version gates](#version-gates)
- [What CBO does / doesn't](#what-cbo-does--doesnt)
- [Verify CBO ran](#verify-cbo-ran)
- [Statistics — the prerequisite](#statistics--the-prerequisite)
- [Join algorithms & order](#join-algorithms--order)
- [Hints](#hints)

## Version gates
CBO is Enterprise Edition / Capella only.

| Version | Behavior |
|---|---|
| 7.0 | CBO GA (preview in 6.5); statistics gathered **manually** via `UPDATE STATISTICS`. |
| 7.6 | Auto-gathers stats when an index is created/built; richer join enumeration; `INCLUDE MISSING`. |
| 8.0+ | Auto Update Statistics (AUS) keeps stats fresh on a schedule. |

Pre-7.6 (or 7.6+ on a collection whose index predates the upgrade) → you must run `UPDATE STATISTICS` yourself.

## What CBO does / doesn't
- **Does:** estimate cost of alternative join orders & access paths from stats; pick the cheaper plan; choose `NestedLoopJoin` vs `HashJoin` by cardinality.
- **Doesn't:** pick a better secondary index for a single-keyspace query when stats are missing (falls back to rule-based); fix a query with no usable index; help when stats are stale.

## Verify CBO ran
Look for an `optimizer_estimates` block on each operator in the `EXPLAIN` output:
```json
"optimizer_estimates": { "cardinality": 24024, "cost": 4108.6, "fr_cost": 12.17, "size": 11 }
```
Absent or placeholder values ⇒ CBO didn't run: disabled, no stats, or pre-7.6.

Disable for one request (rarely needed — fix stats instead): `SET \`query_use_cbo\` = false;`

## Statistics — the prerequisite
```sql
UPDATE STATISTICS FOR `travel-sample`.inventory.hotel(state, city, name);  -- per keyspace + the keys you query
```
Symptoms of missing/stale stats: no `optimizer_estimates`, joins are **always** `NestedLoopJoin` (HashJoin needs cardinality), or the plan matches the old rule-based one. Refresh after bulk loads; schedule weekly (pre-8.0).

⚠️ `UPDATE STATISTICS` is a **write** — blocked in the MCP server's default read-only mode. Treat like
`CREATE INDEX`: hand the statement to the user, or run via `run_sql_plus_plus_query` only with write mode enabled.

## Join algorithms & order
| Algorithm | Planner picks when | Notes |
|---|---|---|
| `NestedLoopJoin` | Outer side small, inner side indexed | Cheap when outer < a few hundred rows; inner `~child` must be `IndexScan3`. |
| `HashJoin` | Both sides non-trivial, cardinality known | Builds hash of the smaller side, probes with the larger. |

- **Drive from the most selective side**: the keyspace whose `WHERE` filters hardest should be the outer/build side. CBO reorders automatically when stats are good.
- **Probe-side index**: for `a JOIN b ON a.id = b.fk`, `b` needs an index on `fk`, else the join falls back to scanning all of `b` per `a`-row. Include the projected `b` columns to cover the join.
- Prefer **ANSI** `JOIN … ON <pred>` over legacy lookup `JOIN … ON KEY[S]` for new work (works on any indexed field, supports HASH/NL).

## Hints
Hints override CBO for one query. They are **duct tape** — prefer fixing the root cause (restructure keys, refresh stats, fix join order). Use a hint only when EXPLAIN confirms the forced plan is genuinely better, or for a transient situation (mid-migration).

| Hint | Form | Forces |
|---|---|---|
| Join order | `SELECT /*+ ORDERED */ …` | FROM-clause order; CBO won't reorder. |
| Join algorithm | `… JOIN b USE HASH(probe) …` / `USE HASH(build)` / `USE NL …` | hash (which side builds) or nested-loop. |
| Index | `… FROM ks USE INDEX (idx USING GSI) …` | a specific index (works rule-based or CBO). |

A `productivity` hint also exists for foreign-key joins where most small-side rows find a match (prevents CBO over-estimating join cardinality) — confirm current syntax in the official docs before suggesting it.
