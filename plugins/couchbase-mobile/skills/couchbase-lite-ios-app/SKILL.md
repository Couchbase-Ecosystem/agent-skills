---
name: couchbase-lite-ios-app
description: "Build the iOS (Swift) client of a Couchbase Mobile app — Couchbase Lite Swift SDK (open DB, CRUD, live query, replicator, full-text search, blobs), SDK installation, automated Xcode project generation, iOS best practices, a diagnostics view, and two-simulator offline-sync testing. A client *capability* invoked by a recipe (`couchbase-mobile-cloud-edge-sync-app`), NOT a standalone starting point — to build an app, start from that recipe. Today it implements only the cloud-edge (Capella App Services) replicator; peer-to-peer and Edge Server are NOT built — never offer them or ask 'which sync topology'."
---

# Couchbase Lite iOS App

Generate and wire up the iOS/Swift app for an offline-first Couchbase Mobile app using the Couchbase Lite Swift SDK. The goal is a project the user can open in Xcode and build immediately — never ask them to create the Xcode project manually.

> **⛔ SCOPE GUARD — read first.** The only Couchbase Mobile app buildable with these skills today is **cloud-edge sync on iOS**. **Peer-to-peer and Edge Server are NOT built.** Do not offer them, do not ask "which sync topology," and never generate P2P/Edge-Server code. If a user wants to *build* an app, that flow lives in the **`couchbase-mobile-cloud-edge-sync-app`** recipe — this skill is a capability that recipe calls, not an entry point; if you're here without the recipe, load it and follow it.

## Replicator: cloud-edge only today (topology-neutral by design)

The SDK, Xcode scaffolding, iOS conventions, testing, and diagnostics here are identical regardless of sync topology — so this skill is topology-neutral *by design*. **But today it implements only the cloud ↔ edge replicator:** a `URLEndpoint` replicator syncing to Capella App Services (see `reference/cbl-swift-apis.md`).

Peer-to-peer (`URLEndpointListener` + `MessageEndpoint`) is **future and not built** — a `reference/p2p-replicator.md` will be added later, and P2P will extend *this* skill (not a new one). Until it exists, **do not offer P2P or generate P2P code.**

## When to use

Building the iOS/Swift client of a **cloud-edge** Couchbase Mobile app (the only implemented topology): using the CBL Swift API, scaffolding the Xcode project, applying Apple conventions, adding the diagnostics view, or the two-simulator offline-sync test.

## What it covers

- `reference/canonical-references.md` — the retail demo (project structure/build settings), CBL Swift docs, and Apple Developer docs to consult before generating code.
- `reference/cbl-swift-apis.md` — open database, CRUD, live query, replicator setup, full-text search, blobs.
- `reference/installation-and-plist.md` — adding the CBL Swift package and the Info.plist app-configuration pattern.
- `reference/xcode-project-generation.md` — generating the `.xcodeproj`, required Info.plist keys, `project.pbxproj` rules, and the exact message to give the user afterward.
- `reference/appconfig-swift.md` — the required `AppConfig.swift` constants (the iOS surface of the domain parameters).
- `reference/ios-best-practices.md` — state/data flow, Keychain credential storage, async/await, toolbar placement, `[weak self]` in CBL callbacks, privacy manifest, iOS requirements.
- `reference/testing-offline-sync.md` — two-simulator offline-first test procedure and troubleshooting.
- `reference/diagnostics-view.md` — the Settings/Diagnostics view to include in every generated app.

## Assets

Drop-in files for the generated Xcode project:

- `assets/KeychainHelper.swift` — secure credential storage (enables sign-out and reconnect-after-relaunch).
- `assets/PrivacyInfo.xcprivacy` — minimal privacy manifest required for iOS 17+ App Store submission.
- `assets/Info-plist-keys.md` — the one app-specific `Info.plist` key (`AppServicesEndpointURL`) to add; `setup-capella.sh` fills it in.

The full `.xcodeproj`/`project.pbxproj` is intentionally **not** an asset — it's generated per `reference/xcode-project-generation.md`, using the public Retail Demo (`reference/canonical-references.md`) as the build-settings ground truth.

## Depends on

Domain parameters (collection names, assignee field, endpoint name) are supplied by the recipe (e.g. `couchbase-mobile-cloud-edge-sync-app`). Sync topology and channel design come from **`couchbase-mobile-concepts-patterns`**. The backend it connects to is stood up by **`couchbase-appservices-provisioning`**.

## Sibling capabilities

`couchbase-lite-android-app` (Kotlin) and `couchbase-lite-web-app` (CBL-JS) are the offline-first platform peers; `couchbase-rest-web-client` is the online/REST alternative (no local DB). This skill is iOS only, and today implements **cloud-edge sync only** (P2P is future/not built — see the scope guard above).

## Asking the user questions

Some clients render only `AskUserQuestion` option **labels**, not their per-option `description`. Because these skills are shared, keep the experience consistent whenever you ask the user anything:
- Ask **one question at a time** — do not batch.
- For any non-obvious choice, first **state the options and what each means as plain text in your message**, then ask.
- Make labels **self-describing** (e.g. `Admin-Assigns (manager assigns, user updates)`) so a bare label still conveys the choice.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team.
