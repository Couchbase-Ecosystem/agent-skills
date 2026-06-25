# Migrating from a relational database

When the user is coming from PostgreSQL, MySQL, Oracle, SQL Server, or any other relational database, half the modeling battle is unlearning instincts. This reference covers the common pitfalls of "translating SQL to Couchbase" and the right way to think about the same problems.

## The fundamental shift

Relational: third-normal form by default, denormalize only when forced to by performance.

Document: model the access patterns by default, normalize only when forced to by write patterns.

Concretely: in SQL you'd start with separate `users`, `orders`, `order_items`, `addresses` tables and JOIN them at query time. In Couchbase, you'd start with what the application actually reads — perhaps a user document that embeds addresses (1:few, read with the user) and references orders (1:many, separate documents).

The shift isn't "denormalize everything" — it's "let the access pattern, not the entity relationships, drive the structure."

## Translation table

A direct mapping of relational concepts to Couchbase concepts:

| Relational | Couchbase | Notes |
|---|---|---|
| Database | Bucket | Roughly. Bucket is more "container with its own memory budget" |
| Schema | Scope | Both are namespacing within the container |
| Table | Collection | Type-grouping of documents |
| Row | Document | One JSON document per "row" |
| Primary key | Document key (META().id) | Couchbase's key IS the PK; no separate column |
| Column | JSON field | Documents have free shape; no enforced columns |
| Foreign key | Field containing another doc's key | No enforcement — application's job |
| JOIN | N1QL JOIN, or denormalize, or separate fetches | All three are valid; pick by access pattern |
| Index | Index | Similar concept, different mechanics |
| Stored procedure | Eventing function, or N1QL UDF | Both exist; Eventing is event-driven, UDFs are query-time |
| Trigger | Eventing function | Eventing functions can be triggered by document mutations |
| View | N1QL query | Or Analytics service for materialized views |
| Transaction | Couchbase transaction (SDK) | Slower than KV; use when atomicity matters |

## Patterns that translate well

These relational patterns work essentially the same in Couchbase:

- **Lookup by ID**: `SELECT * FROM users WHERE id = 42` → KV `GET` with key `user::42`. Couchbase is much faster here because KV is direct
- **Filtering by indexed column**: `SELECT * FROM users WHERE tier = 'gold'` → same SQL++ with a secondary index on `tier`
- **Aggregation**: `SELECT COUNT(*), AVG(value) FROM ... GROUP BY ...` → same SQL++. Use Analytics service if it's a heavy ad-hoc query
- **Many-to-many through a join table**: keep the join table pattern (bridge documents). Doesn't translate to embedding when both sides are unbounded

## Patterns that DON'T translate well

### "I'll just use N1QL JOINs for everything"

You can. `SELECT u.*, o.* FROM users u JOIN orders o ON u.id = o.user_id` is valid SQL++. But:
- JOINs require indexes on both sides
- Distributed JOINs across nodes have network cost
- It's often faster to fetch the parent doc (KV), then issue a follow-up KV multi-get for the children, than to JOIN

The right mental shift: ask "do I need ALL fields of both, or only a subset?" If subset, project the subset. If all, consider denormalization or two KV fetches.

### "Normalize everything"

The relational instinct of "Customer has Address, so Address is a separate table" produces models like:

```json
// users collection
{ "id": "user::42", "name": "Alice", "address_id": "addr::789" }

// addresses collection  
{ "id": "addr::789", "street": "...", "city": "...", ... }
```

This means every user lookup is two KV fetches (or one JOIN). For something as 1:1-with-user as an address, embed it:

```json
{
  "id": "user::42",
  "name": "Alice",
  "address": { "street": "...", "city": "...", ... }
}
```

One fetch, simpler code, no inconsistency window.

### "I need a sequence for IDs"

SQL has `SERIAL` / `AUTO_INCREMENT`. Couchbase doesn't (well, it does — see counters in `keys.md`), and using one is usually a mistake.

Reasons to prefer ULIDs over sequential IDs in Couchbase:
- No write hot spot (sequential IDs hash to similar vBuckets)
- Time-orderable (ULIDs sort by creation time)
- Distributed-friendly (multiple clients can generate IDs without coordination)
- No counter document to maintain

The exception: when users need to remember/type the ID (invoice numbers, order references). Then use a counter, accept the hot-spot cost, and consider sharding the counter.

### "I'll use a single table for polymorphic data"

In SQL, the pattern of `polymorphic_table(id, type, common_fields..., type_specific_fields...)` with sparse columns is a known smell but sometimes used.

In Couchbase the equivalent looks fine — documents in the same collection can have different shapes. But it falls apart fast:
- Indexes have to handle all the shapes
- Schema-by-accident emerges
- Queries become hard to optimize

Better: separate collections per type, even if they share a few common fields. The few common fields can be denormalized into both.

## Patterns that are easier in Couchbase

### Nested data

Relational: `user has address has city has country has ...` requires many tables and JOINs.

Couchbase: just nest it.

```json
{
  "id": "user::42",
  "addresses": [
    {
      "type": "home",
      "street": "...",
      "city": { "name": "Seattle", "country": { "code": "US", "name": "USA" } }
    }
  ]
}
```

A single fetch gets you everything.

### Optional fields and varying schemas

Relational: every column exists for every row; optional fields are NULL.

Couchbase: fields just don't exist if they don't apply. A `temporary` user might have an `expires_at` field that permanent users don't have. Code uses `IS MISSING` to check.

This is genuinely easier than the relational equivalent.

### Adding a field

Relational: `ALTER TABLE` and possibly a long migration.

Couchbase: just start writing the new field. Old documents without it have it missing; queries handle that via `IS MISSING` or `IFMISSING()`. Use a `_v` field if you want explicit migration tracking.

## Two migration approaches

If you're actually migrating an existing relational DB to Couchbase:

### Approach 1 — Direct translation (anti-pattern)

Take each relational table and turn it into a Couchbase collection. Same schema, same keys, same foreign-key fields.

**Problem:** you've spent the migration cost and ended up with a relational design in a document database. You get neither the consistency benefits of relational nor the access-pattern benefits of document. The application code still issues JOIN-equivalent queries; performance is no better.

This is the most common migration outcome and almost always regretted.

### Approach 2 — Re-model for access patterns

For each user-facing read in the application:
1. List every relational table involved
2. Ask "could these be one document?"
3. If yes (1:1 or bounded 1:few), embed
4. If no (unbounded 1:many or many:many), separate documents with references

Result: fewer collections than tables, but each collection's documents are richer.

**Cost:** the migration is bigger because the schema fundamentally changed. Application code also needs adjusting (KV gets instead of JOINs).

**Payoff:** queries that took JOINs in SQL become single KV fetches.

### Hybrid: cold-side translation, hot-side re-model

For low-traffic reads (admin reports, batch jobs), direct translation is fine — the slight inefficiency doesn't matter and the migration is faster.

For high-traffic reads (the actual app pages), re-model for access patterns.

This pragmatic split is often the right answer.

## Specific source-DB notes

### From PostgreSQL

- JSONB columns translate trivially — they're already JSON
- Sequences → ULIDs or per-doc keys (avoid the counter pattern unless needed)
- PL/pgSQL stored procedures → Eventing functions (JS) or N1QL UDFs
- Materialized views → Analytics service or maintained summary documents
- LISTEN/NOTIFY → Eventing functions can subscribe to mutations

### From MySQL

- AUTO_INCREMENT → ULID (much better) or counter
- ENUM columns → string field with application-level validation
- Stored procedures → Eventing functions
- Replication → XDCR (different model — bidirectional possible, conflict resolution is configurable)

### From Oracle

- Sequences → ULID or counter
- Materialized views → Analytics service
- PL/SQL → Eventing functions (JS)
- DBA Privileges → Couchbase RBAC roles (see Couchbase documentation)

### From SQL Server

- Identity columns → ULID
- T-SQL stored procedures → Eventing functions
- Filtered indexes → use array indexes or partial indexes (Couchbase has `INCLUDE MISSING` and `WHERE` clauses in CREATE INDEX)

## Don't migrate everything at once

For any non-trivial migration:

1. Pick one bounded slice of the application (one feature, one module)
2. Re-model just that slice for Couchbase
3. Run dual-write: write to both old DB and Couchbase for the slice
4. Read from Couchbase, verify it matches; if not, fix and continue dual-write
5. Once stable, cut reads over to Couchbase entirely
6. Eventually remove the relational tables for that slice
7. Repeat for the next slice

Big-bang migrations of relational to document have a high failure rate. Slicing keeps the blast radius small at each step.

## Quick decision tree

- **Direct ID lookup?** → KV get, faster than relational
- **1:1 or bounded 1:few?** → embed in the parent document
- **1:many unbounded or many:many?** → separate documents, links via foreign-key-style field
- **Polymorphic table?** → separate collections per type
- **Need transactions across multiple docs?** → Couchbase transaction via SDK (slower than KV; use sparingly)
- **Migrating?** → re-model for access patterns on hot paths; direct translation on cold paths
- **Need ALTER TABLE?** → you don't; just start writing the new field and use a version marker
