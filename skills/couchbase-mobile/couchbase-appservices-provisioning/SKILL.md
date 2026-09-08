---
name: couchbase-appservices-provisioning
description: "Automated provisioning of Capella App Services via a generated setup-capella.sh — Capella Management API (OpenAPI) usage, free-tier API rules, dependency ordering, idempotency, required env vars, App Endpoint lifecycle, default users, and manual fallback. Use when setting up the Capella/App Services backend for a Couchbase Mobile app, generating or debugging setup-capella.sh, or bringing an App Endpoint online. Tier/server capability for cloud-edge and Edge Server recipes; NOT used by pure P2P apps."
---

# Couchbase App Services Provisioning

Provision the Capella + App Services backend for an offline-first app with maximum automation, primarily by generating and running `setup-capella.sh`. App Services runs on Capella, so this covers both the Capella control plane (cluster/API) and App Services configuration.

## When to use

Standing up the backend: creating the cluster/bucket, App Endpoint, users and roles, uploading Access Control Functions, and bringing the endpoint online — or debugging any of those.

## How to work

1. **Know which REST API you're calling** — `reference/rest-apis.md` distinguishes the three surfaces (Capella Management API for cluster/endpoint provisioning; App Services **Admin** REST API for roles/users/channels; App Services **Public** REST API for clients, out of scope here). **Always read the Management API spec before generating any Management API call** — `reference/management-api.md` explains where the OpenAPI spec is and how to query it. Do not hand-write endpoints from memory.
2. Use the bundled **`assets/setup-capella.sh`** — a complete, idempotent, env-parameterized script. Copy it into the user's project and drive it entirely via env vars (`CB_API_KEY`, `COLLECTIONS`, `CB_ENDPOINT_NAME`, etc.); do not hand-rewrite it. `reference/script-generation.md` (script rules) and `reference/script-structure.md` (dependency ordering, idempotency, required env vars, script flow, default users) explain how it works and how to modify it if the data model needs it.
3. Respect the free-tier constraints in `reference/free-tier-api.md`.
4. Hand the user the run steps and finish per `reference/backend-setup.md` (the user runs it themselves + the 2 remaining steps + manual fallback).
5. For endpoint/domain specifics — App Endpoint naming, sync-function filenames matching `COLLECTIONS`, and the online/offline lifecycle — see `reference/domain-endpoint-config.md`.

## Depends on

The Access Control Functions to upload come from **`couchbase-mobile-access-control-function`**; the collection/channel design comes from **`couchbase-mobile-concepts-patterns`**. The `COLLECTIONS` env var, access control function filenames, and collection names must all agree.

## Non-goals

Does not write the access control function logic itself, and does not apply to pure P2P apps (no central backend).

## Platform-neutral — do NOT prompt for platform

This capability is **client-platform agnostic**: the backend it provisions (cluster, bucket, collections, App Endpoint, access control functions, roles, users) is identical for iOS, Android, and web. **Do not ask the user which platform** — that's the calling recipe's concern (the recipe already knows). The only platform-specific action is wiring the resulting **WSS endpoint URL** into the client's config, and the script handles that by *detection*, not a prompt:
- **iOS** — if it finds an `Info.plist`, it writes the `AppServicesEndpointURL` key (macOS `plutil`).
- **Android** — else if it finds a `local.properties` beside a `settings.gradle(.kts)`, it writes/updates the `cbl.endpointUrl` key (which the app exposes via `BuildConfig`; the user re-syncs Gradle afterward). See `couchbase-lite-android-app/assets/config-keys.md`.
- **Otherwise** — it **prints the WSS URL** for the recipe/user to place into whatever the client uses (a web `.env`, etc.).

Future web/other recipes reuse this skill unchanged and own their own client-config wiring.

## Assets

- `assets/setup-capella.sh` — the canonical provisioning script (idempotent, safe to re-run, fully env-parameterized). This is the source of truth; the `reference/` files document its rules and structure. Copy and run it — don't regenerate it from scratch.
- `assets/provision.env.example` — the config template the script reads. Copy to `provision.env`, pre-fill the app-specific values (`CB_ENDPOINT_NAME`, `COLLECTIONS`, `SYNC_FUNCTIONS_DIR`) to match the app, leave the two secrets (`CB_API_KEY`, `APPSVC_ADMIN_PASS`) blank for the user. Run with `source provision.env && ./setup-capella.sh`.

## Seed / test data — ask first, always label

`setup-capella.sh` provisions **infrastructure only** (cluster, bucket, collections, endpoint, access control functions, roles, users) — it **never creates documents**. Any documents in the backend come from explicit writes, so:

- **Announce before writing.** Before creating, updating, or deleting ANY document in the user's backend — whether to verify access-control routing or to seed demo data — state up front *what* you're writing, *why*, and whether you'll delete it or keep it. Never write to their cluster silently.
- **Label test docs.** Give verification documents an obvious prefix like `zz-test-` (or `test-`) and offer to delete them when the check is done. Echo exactly what you created.
- **Offer seed data — don't assume.** Once the App Endpoint is Online, **ask** whether the user wants a small set of demo documents so the app has something to show on first run (e.g. one record assigned to `bob` + one shared reference for the Shared-Read-Only pattern). Create them only on a yes, label/echo them, and say how to remove them.

## Asking the user questions

Some clients render only `AskUserQuestion` option **labels**, not their per-option `description`. Because these skills are shared, keep the experience consistent whenever you ask the user anything:
- Ask **one question at a time** — do not batch.
- For any non-obvious choice, first **state the options and what each means as plain text in your message**, then ask.
- Make labels **self-describing** (e.g. `Admin-Assigns (manager assigns, user updates)`) so a bare label still conveys the choice.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team.
