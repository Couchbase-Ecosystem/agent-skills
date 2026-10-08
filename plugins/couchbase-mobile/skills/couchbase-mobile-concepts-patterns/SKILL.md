---
name: couchbase-mobile-concepts-patterns
description: "Foundational concepts, terminology, and patterns for Couchbase Mobile — App Services vs Sync Gateway terminology mapping, core sync concepts (channels, replication, offline-first), data modeling (scopes and collections, key design), the architecture pattern, and the standard access patterns (Admin-Assigns, Shared Read-Only, Team/Group). Use when explaining how Couchbase Mobile sync works, designing the document model, choosing scopes/collections, mapping terms between App Services and self-managed, or deciding an access pattern. Concepts only — it does NOT build apps; to build one use the `couchbase-mobile-cloud-edge-sync-app` recipe. Only cloud-edge sync (on iOS or Android) is buildable today; P2P and Edge Server are described for context but are not implemented — never offer them as build options or ask 'which sync topology'."
---

# Couchbase Mobile Concepts & Patterns

Platform- and topology-neutral foundations for Couchbase Mobile: the terminology, core sync concepts, data modeling, and the standard access patterns. This is a *concepts* capability — it explains ideas; it does not build apps.

> **⛔ SCOPE GUARD — read first.** This skill may *describe* several sync topologies (cloud-edge, peer-to-peer, Edge Server) so you understand the landscape, but only **cloud-edge sync is actually buildable today — on iOS or Android** — P2P and Edge Server are **not implemented**. So: **do not ask "which sync topology," do not offer P2P/Edge Server as build options, and never scaffold one.** If the user wants to *build* an app, that is driven by the **`couchbase-mobile-cloud-edge-sync-app`** recipe — load and follow it (this concepts skill is something the recipe pulls in, not a standalone build entry point).

## When to use

Reach for this whenever the task involves: the document model, key design, choosing a named scope and collections, the difference between App Services and Sync Gateway, or picking an access pattern before any Access Control Function is written.

## What it covers

Read `reference/concepts-and-modeling.md` for the full detail. It contains:

- **Terminology** — App Services vs Sync Gateway, and how the terms map.
- **Core concepts** — databases, collections, channels, replication, offline-first behavior.
- **Data modeling** — always use a *named* scope (never `_default`); one collection per document type; how collection names flow through to channels and Access Control Functions.
- **Architecture pattern** — local-first reads, replicator as background infrastructure.
- **Standard access patterns** — Admin-Assigns (default), Shared Read-Only, Team/Group. These are the conceptual definitions; the Access Control Function *implementation* of each lives in the `couchbase-mobile-access-control-function` skill.

## Hand-offs

- To implement an access pattern as an Access Control Function → load **`couchbase-mobile-access-control-function`**.
- To provision the backend that enforces these channels → load **`couchbase-appservices-provisioning`**.
- Collection names chosen here must match the `COLLECTIONS` env var used by provisioning and the sync-function filenames — keep them consistent end to end.

## Key rule

Design channels and collections **before** writing any client or backend code. The collection name is the contract shared by the client, the Access Control Function, and the provisioning script.

## Asking the user questions

Some clients render only `AskUserQuestion` option **labels**, not their per-option `description`. Because these skills are shared, keep the experience consistent whenever you ask the user anything:
- Ask **one question at a time** — do not batch.
- For any non-obvious choice, first **state the options and what each means as plain text in your message**, then ask.
- Make labels **self-describing** (e.g. `Admin-Assigns (manager assigns, user updates)`) so a bare label still conveys the choice.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team.
