---
name: couchbase-lite-android-app
description: "Build the Android (Kotlin/Jetpack Compose) client of a Couchbase Mobile app — Couchbase Lite Android SDK (init, open DB, CRUD, live query via Kotlin Flow, replicator, full-text search, blobs), Gradle/SDK installation, automated Android project generation, Android best practices, a diagnostics screen, and two-emulator offline-sync testing. A client *capability* invoked by a recipe (`couchbase-mobile-cloud-edge-sync-app`), NOT a standalone starting point — to build an app, start from that recipe. Today it implements only the cloud-edge (Capella App Services) replicator; peer-to-peer and Edge Server are NOT built — never offer them or ask 'which sync topology'."
---

# Couchbase Lite Android App

Generate and wire up the Android/Kotlin app for an offline-first Couchbase Mobile app using the Couchbase Lite Android SDK. The goal is a project the user can open in Android Studio and build immediately — never ask them to create the Gradle project manually.

> **⛔ SCOPE GUARD — read first.** The only Couchbase Mobile app buildable with these skills today is **cloud-edge sync on Android**. **Peer-to-peer and Edge Server are NOT built.** Do not offer them, do not ask "which sync topology," and never generate P2P/Edge-Server code. If a user wants to *build* an app, that flow lives in the **`couchbase-mobile-cloud-edge-sync-app`** recipe — this skill is a capability that recipe calls, not an entry point; if you're here without the recipe, load it and follow it.

## Replicator: cloud-edge only today (topology-neutral by design)

The SDK, Gradle scaffolding, Android conventions, testing, and diagnostics here are identical regardless of sync topology — so this skill is topology-neutral *by design*. **But today it implements only the cloud ↔ edge replicator:** a `URLEndpoint` replicator syncing to Capella App Services (see `reference/cbl-kotlin-apis.md`).

Peer-to-peer (`URLEndpointListener` / multipeer) is **future and not built** — it requires the Enterprise Edition of the SDK and will *extend this skill* later (a `reference/p2p-replicator.md`), not a new skill. Until it exists, **do not offer P2P or generate P2P code.**

## When to use

Building the Android/Kotlin client of a **cloud-edge** Couchbase Mobile app (the only implemented topology): using the CBL Android/Kotlin API, scaffolding the Gradle project, applying Android conventions, adding the diagnostics screen, or the two-emulator offline-sync test.

## What it covers

- `reference/canonical-references.md` — the retail demo (Gradle project structure / dependency wiring), CBL Android docs, and Android developer docs to consult before generating code.
- `reference/cbl-kotlin-apis.md` — init the SDK, open database, CRUD, live query (Kotlin Flow + listener token), replicator setup, full-text search, blobs.
- `reference/installation-and-config.md` — adding the CBL Android package (Enterprise Edition, custom Couchbase Maven repo), the toolchain compatibility band, and the `BuildConfig`-from-`local.properties` app-configuration pattern.
- `reference/gradle-project-generation.md` — generating the Gradle project (`settings.gradle.kts`, `build.gradle.kts`, `AndroidManifest.xml`), required config, mandatory code-gen rules, and the exact message to give the user afterward.
- `reference/appconfig-kotlin.md` — the required `AppConfig.kt` constants (the Android surface of the domain parameters).
- `reference/android-best-practices.md` — state/data flow (ViewModel/StateFlow/Compose), secure credential storage (Android Keystore), coroutines/lifecycle, listener-token cleanup, role-gated UI, and Android requirements.
- `reference/testing-offline-sync.md` — two-emulator offline-first test procedure and troubleshooting.
- `reference/diagnostics-view.md` — the Settings/Diagnostics screen to include in every generated app.

## Assets

Drop-in files for the generated Gradle project:

- `assets/CredentialStore.kt` — secure credential storage backed by the Android Keystore (AES-GCM), no deprecated dependencies (enables sign-out and reconnect-after-relaunch). The Keychain equivalent of the iOS skill's `KeychainHelper.swift`.
- `assets/config-keys.md` — the one app-specific config value (`AppServicesEndpointURL`) and how `setup-capella.sh` wires it into `local.properties` → `BuildConfig`.

The full Gradle project (`build.gradle.kts` / `settings.gradle.kts` / `AndroidManifest.xml`) is intentionally **not** a static asset — it's generated per `reference/gradle-project-generation.md`, using the public Retail Demo (`reference/canonical-references.md`) as the build-settings ground truth.

## Depends on

Domain parameters (collection names, assignee field, endpoint name) are supplied by the recipe (e.g. `couchbase-mobile-cloud-edge-sync-app`). Sync topology and channel design come from **`couchbase-mobile-concepts-patterns`**. The backend it connects to is stood up by **`couchbase-appservices-provisioning`** (which also writes the WebSocket URL into this app's `local.properties`).

## Sibling capabilities

`couchbase-lite-ios-app` (Swift) and `couchbase-lite-web-app` (CBL-JS, future) are the offline-first platform peers; `couchbase-rest-web-client` (future) is the online/REST alternative (no local DB). This skill is Android only, and today implements **cloud-edge sync only** (P2P is future/not built — see the scope guard above).

## Asking the user questions

Some clients render only `AskUserQuestion` option **labels**, not their per-option `description`. Because these skills are shared, keep the experience consistent whenever you ask the user anything:
- Ask **one question at a time** — do not batch.
- For any non-obvious choice, first **state the options and what each means as plain text in your message**, then ask.
- Make labels **self-describing** (e.g. `Admin-Assigns (manager assigns, user updates)`) so a bare label still conveys the choice.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team.
