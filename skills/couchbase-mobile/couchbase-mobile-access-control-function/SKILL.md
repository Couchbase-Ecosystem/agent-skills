---
name: couchbase-mobile-access-control-function
description: "Author the JavaScript function that controls document access and routes documents to channels in Couchbase Mobile — called an Access Control Function in Capella App Services and a sync function in Sync Gateway / on-prem, but the same function either way. Covers channel/access rules, file-generation conventions, the Admin-Assigns and Shared-Reference templates, and the role/channel/collection_access rules learned from real bugs. Use when writing or debugging an access control function or sync function, wiring channels to users/roles, or when App Services silently ignores flat admin_channels for named scopes. Cross-cutting capability reused by cloud-edge and Edge Server recipes; NOT used by pure P2P apps."
---

# Couchbase Mobile Access Control Functions

How to write the correct JavaScript function that enforces document access and routes documents to channels in Couchbase Mobile. Context-neutral: it does not assume a domain or app.

**Terminology — same function, two names.** Capella App Services calls it an **Access Control Function** (often abbreviated **ACF**); Sync Gateway (and on-prem deployments) call it a **sync function**. Access Control Function, ACF, and sync function all mean the same thing — the JavaScript is identical regardless of where it is deployed (App Services, Sync Gateway, or an Edge Server upstream link). Users coming from on-prem will often say "sync function" even when working in Capella; treat all three terms as interchangeable throughout this skill.

## When to use

Writing an access control function for a collection, mapping documents to channels, granting users/roles access, or debugging why access isn't working (documents not syncing, `admin_channels` ignored, role access not inherited).

## What it covers

- `reference/access-control-function-rules.md` — the core rules for what an access control function must do, and the file-generation conventions (one access control function file per collection, filenames match collection names).
- `reference/access-control-function-templates.md` — ready templates: the **Admin-Assigns** pattern (default) and the **Shared Reference** pattern. Includes the `collection_access` / `build_collection_access()` approach for named scopes.
- `reference/role-channel-rules.md` — **critical bug-learnings**: why the `role:` prefix works on self-managed Sync Gateway but breaks on App Services (so drop it for App Services); why flat `admin_channels` is silently ignored for named scopes; how role→channel access is inherited via `admin_roles`; how to set `collection_access` per scope/collection.
- `reference/admin-access-patterns.md` — the menu of ways to model an "admin": role vs user, `*` (all channels) vs named `admin` channel vs selective per-user channels, and static-REST vs dynamic-`access()` grants (with the "grant constant access statically, not per function-run" performance rule). Start from FieldTaskTracker's approach and expand.
- `reference/example-comprehensive-access-model.md` — a full worked example (from FieldTaskTracker): App Users + an admin **role** with all-access, per-user channels, a public `!` channel, admin-assigns, field validation, immutable fields, and status-locking — with the access control functions written in the corrected idiom. Use when the app needs more than simple per-tenant/store isolation.

## Output — write real files (one per collection)

The deliverable is **actual `.js` files on disk**, not a description in chat. Write **one file per collection** in `COLLECTIONS`, named exactly `<collection>-sync-function.js`, into the project's `sync-functions/` folder (the folder `SYNC_FUNCTIONS_DIR` will point at). Example: `COLLECTIONS='retail/transactions retail/inventory'` → create `sync-functions/transactions-sync-function.js` **and** `sync-functions/inventory-sync-function.js`. The provisioning script uploads these and **FATALs if any is missing** — so create them before provisioning runs.

## Depends on

Assumes a document model and a chosen access pattern — get those from **`couchbase-mobile-concepts-patterns`** first. The scope/collection names here must match the `COLLECTIONS` env var and sync-function filenames used by **`couchbase-appservices-provisioning`**.

## Non-goals

Does not provision the backend or run the API calls (that's `couchbase-appservices-provisioning`). Does not apply to pure peer-to-peer apps, which have no channels or access control functions.

## Assets

Copy-ready access control functions in the corrected App Services idiom — drop into the user's `sync-functions/` folder and adapt the `DOC_TYPE`/field names:

- `assets/admin-assigns-sync-function.js` — per-user private channel + admin channel, admin-assigns, validation, status-lock (the default pattern).
- `assets/shared-reference-sync-function.js` — public `!` channel, read-only for users, admin-write.

`reference/access-control-function-templates.md` keeps the annotated explanations; the `assets/` files are the canonical copies to deploy.

## Asking the user questions

Some clients render only `AskUserQuestion` option **labels**, not their per-option `description`. Because these skills are shared, keep the experience consistent whenever you ask the user anything:
- Ask **one question at a time** — do not batch.
- For any non-obvious choice, first **state the options and what each means as plain text in your message**, then ask.
- Make labels **self-describing** (e.g. `Admin-Assigns (manager assigns, user updates)`) so a bare label still conveys the choice.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team.
