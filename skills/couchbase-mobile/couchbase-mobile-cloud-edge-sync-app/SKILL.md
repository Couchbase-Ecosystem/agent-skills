---
name: couchbase-mobile-cloud-edge-sync-app
description: "START HERE to BUILD a Couchbase Mobile app — the entry-point recipe (the concepts, access-control, provisioning, and client skills are capabilities this recipe pulls in; don't drive a build from them directly). Triggers: 'build a Couchbase Mobile app', 'mobile app with data sync', 'Couchbase Mobile', 'offline-first app', 'Couchbase Lite', 'CBL', 'App Services', 'Capella sync'. Builds an offline-first app that syncs bidirectionally between Capella App Services (cloud) and each device's local Couchbase Lite DB, for ANY domain (field ops, retail POS, airline meal ordering, inventory…). **This cloud-edge topology is buildable on iOS (Swift) and Android (Kotlin) today** — peer-to-peer and Edge Server are NOT built and must not be offered or asked about; web and other clients are future. Asks a couple of upfront questions (platform, domain, access pattern); the domain is a runtime parameter, not a separate skill."
---

# Couchbase Mobile — Cloud ↔ Edge Sync App (recipe)

You are an expert in building offline-first apps with **Couchbase Lite** and **Capella App Services**. This recipe takes the user from zero to a working, openable app **with as few manual steps as possible**, for whatever *domain* they name — field ops, retail POS, airline meal ordering, warehouse inventory, etc. The domain only changes the nouns (collection names, the "assignee" field, sample data); the technical shape is identical.

This is a thin orchestrator. It owns the workflow and parameterization; it delegates all substance to capability skills.

## Scope

This recipe deploys the backend **end-to-end on Capella App Services** — the managed, cloud-hosted target. Self-managed / local Sync Gateway deployment is **out of scope** here and will be covered by separate instructions in future. Provisioning, scripts, and generated artifacts therefore use App Services terminology; when *explaining* concepts conversationally, still mirror whatever term the user uses (see `couchbase-mobile-concepts-patterns`).

## Sync topology — only cloud-edge is built today

Couchbase Mobile supports three sync topologies, but **this recipe only builds cloud-edge**:

- **Cloud-edge (Capella App Services)** — ✅ available now (this recipe).
- **Peer-to-peer (device-to-device)** — 🚧 planned as a separate `couchbase-mobile-p2p-app` recipe; **not built yet**.
- **Edge Server** — 🚧 planned as a separate `couchbase-edge-server-app` recipe; **not built yet**.

You may briefly mention the three so the user sees the landscape, but **do not present a picker that implies you can build P2P or Edge Server, and never proceed to "build" one — there is no recipe for it.** If the user asks for or selects **P2P or Edge Server**, say plainly: *"Only cloud-edge (Capella App Services) is available today; peer-to-peer and Edge Server are on the roadmap as separate recipes but not built yet. I can build you the cloud-edge version now — want that?"* Proceed only with cloud-edge (or a design-only outline if they insist on discussing the others).

## This recipe composes these skills — load each before use

1. **`couchbase-mobile-concepts-patterns`** — scopes/collections, channels, and the access pattern.
2. **`couchbase-mobile-access-control-function`** — the Access Control Function(s) to deploy.
3. **`couchbase-appservices-provisioning`** — provision the Capella/App Services backend.
4. A **client** capability for the chosen platform — **`couchbase-lite-ios-app`** (iOS/Swift) or **`couchbase-lite-android-app`** (Android/Kotlin). Load the one matching the platform the user picked (web and others are future peers).

## Open by setting expectations — pick the platform (iOS or Android)

**First thing you say** (frame it warmly, roughly): "I can help you build a **cloud-edge (Capella App Services)** Couchbase Mobile app. Data syncs bidirectionally between the cloud and each device's local Couchbase Lite database, so the app works fully offline and reconciles when back online. I can build the **iOS (Swift)** client or the **Android (Kotlin)** client today. **Couchbase Lite supports even more platforms** — web (JS), Flutter, React Native, .NET, and more — planned as separate skills. Two other sync topologies also exist (peer-to-peer and Edge Server); only cloud-edge is available to build right now."

Set the expectations up front — topology is **cloud-edge** (P2P and Edge Server are future recipes, not built — see Sync topology above), and platform is **iOS or Android** (the two vetted clients today). Make clear the remaining platform limits are a **"not yet" in this tooling, not a Couchbase Lite limitation** — CBL is cross-platform; the *web and other client skills* (`couchbase-lite-web-app`, …) just aren't built yet. **Do ask "iOS or Android?" (it's the first upfront question), but do NOT ask "which topology?" or offer the unbuilt platforms/topologies as selectable choices.** (Only if the user explicitly needs web/Flutter/etc., say it isn't supported yet and offer iOS/Android or a design-only outline.) The prerequisites below are **platform-specific** — state the set that matches the platform the user picked, so there's no mismatch.

## Prerequisites — state AND confirm before generating (platform-specific)

State the set matching the platform the user picked, and **confirm the user has them before you generate the client app** — if any are missing, pause and direct them to set it up first. **A free Couchbase Capella account** (https://cloud.couchbase.com, no credit card) is required for both. The `setup-capella.sh` script uses the free-tier API — a paid account is not needed. Users can set these up while you generate the code.

**Edition — this build uses Couchbase Lite Enterprise Edition (EE) by default** (iOS via the `-ee` SPM repos; Android via the `-ee-ktx` coordinate + the custom Couchbase Maven repo). EE is free for development and testing; production deployment requires a Couchbase Enterprise license/subscription. Community Edition (license-free, cloud-edge only) is a documented alternative in the client skills, but do NOT switch to it unless the user asks.

> **Version-alignment rule — this trips most developers.** Before generating the client, ALWAYS: (1) **confirm the user's toolchain VERSION with them** — Xcode for iOS, Android Studio (and its bundled JDK) for Android; then (2) **pin the Couchbase Lite version to match it**. If their toolchain is **below the minimum for the latest CBL (4.x)**, recommend upgrading to that minimum first; fall back to the newest **3.x** line only if they decline. Never pin a CBL version without knowing the toolchain version — a mismatch is the #1 cause of a cryptic first-build failure (`SDK not supported by the compiler` on iOS; Gradle/AGP/JDK errors on Android). The per-platform steps below implement this.

### If iOS

> **Prerequisites (iOS):**
> 1. **Xcode — check the version first, then match the Couchbase Lite SDK to it.** **Xcode 26.2+ is recommended** because it gets the latest Couchbase Lite **4.x** (currently 4.1) — the version we encourage for new apps, and the one future peer-to-peer/Bluetooth support needs. **Xcode 16.x is supported**, but pins to the **3.x** line (use the *newest* 3.x — currently **3.3.0**, not 3.2 — 4.x won't load on Xcode 16.x: `SDK not supported by the compiler`). Check: Xcode → menu → About Xcode.
> 2. **At least two iOS Simulators** installed — the offline-sync test runs the app on two simulators side by side. Check: Xcode → **Window → Devices and Simulators → Simulators**; add more with **+** (e.g. iPhone 16 and iPhone 16 Pro). If fewer than two, add a second now.

**Couchbase Lite version (iOS) — do this before generating the client:**
1. **Find the user's Xcode version** (ask, or have them check About Xcode).
2. **If it's older than 26.2** (e.g. 16.x): **strongly recommend upgrading Xcode** so they get the latest Couchbase Lite 4.x (recommended for new apps; required for future P2P/Bluetooth). Point them to the **Mac App Store** (simplest) or https://developer.apple.com/download/applications/ for a specific version; the latest Xcode may need a recent macOS. If they can't/won't upgrade, **confirm they're OK proceeding with the 3.x line** (newest compatible — 3.3.0).
3. **Pin the SDK to the newest version compatible with the environment** — Xcode 26.2+ → CBL 4.x (`couchbase-lite-swift-ee.git`); Xcode 16.x → newest 3.x, currently **3.3.0** (`couchbase-lite-ios-ee.git`, `upToNextMinor 3.3.0`). Details in `couchbase-lite-ios-app` → `reference/installation-and-plist.md`. Never leave it on `from 4.0.3` for an Xcode-16 user.

**This flow targets the iOS Simulator** — no code signing needed. A physical device is optional and requires a Development Team (Signing & Capabilities). Assume simulators unless the user says otherwise.

### If Android

> **Prerequisites (Android):**
> 1. **Android Studio** (a current release — Giraffe/Koala or newer). It bundles **JDK 17** and a compatible **AGP 8.x / Gradle 8.x**, which the latest Couchbase Lite Android **4.x** (currently 4.1) needs. Check: Android Studio → About. Older setups can pin CBL **3.4.x**, but recommend updating Android Studio first.
> 2. **The Android SDK** — installed **through Android Studio**, not a hand-downloaded ZIP. First launch: **Setup Wizard → Standard** downloads it; otherwise **SDK Manager** (Welcome → *More Actions → SDK Manager*) → **SDK Platforms: Android 15 (API 35)** + **SDK Tools: Build-Tools, Platform-Tools, Emulator** → Apply (default `~/Library/Android/sdk`). The **"Select SDKs — provide the path"** popup means no SDK is installed yet — install it here, don't paste a URL.
> 3. **At least two Android emulators (AVDs)** installed — the offline-sync test runs the app on two side by side. Add via **Device Manager → Add a virtual device** (e.g. two Pixel devices, API 34/35). If fewer than two, add a second now.

> **New to Android Studio (coming from Xcode/iOS)?** **Open the ROOT project folder** (File → Open → the `<AppName>` folder with `settings.gradle.kts`), not one file. The **Android SDK** installs via the **SDK Manager** (there's no App Store download). **Gradle sync** ≈ resolving SPM packages; an **emulator** ≈ a Simulator (create in **Device Manager**); **Run ▶** builds & installs to it.

**Couchbase Lite version (Android) — do this before generating the client:**
1. **Find the user's Android Studio version** (ask, or Android Studio → About). It bundles the JDK and sets the AGP/Gradle floor.
2. **If it's an older release** that can't run **AGP 8 / JDK 17** (roughly pre-2022 / pre-Giraffe): **recommend updating Android Studio** to a current release (Help → Check for Updates, or the Android Studio download page) so they get the latest Couchbase Lite **4.x**. If they can't/won't update, **confirm they're OK on the newest 3.x — 3.4.x** (same Collection/Scope API, same minSdk 22).
3. **Pin the newest CBL compatible with the environment** — modern Android Studio → CBL **4.x** (`couchbase-lite-android-ee-ktx`, Enterprise Edition, from the custom Couchbase Maven repo); older toolchain → **3.4.x**. Details in `couchbase-lite-android-app` → `reference/installation-and-config.md`.
4. **Set the Gradle JVM to 17** (before the first Gradle sync) -- new Android Studio may default it to JDK 24/25, which the bundled **Gradle 8.9** wrapper can't run; this is the #1 first-build failure. **Walk the user through changing it in your reply -- give these exact steps, do NOT just say "set it to 17" or defer to the README:** (1) in Android Studio open **Settings/Preferences -> Build, Execution, Deployment -> Build Tools -> Gradle**; (2) set **Gradle JVM** (older UIs) or **Default Gradle JVM criteria -> Version** (2025+ UIs) to **17** -- pick the **Embedded JDK / JetBrains Runtime (jbr-17)** entry if shown; (3) click **Apply / OK**; (4) **File -> Sync Project with Gradle Files**. **If they skipped step 4a and the first sync already failed** with "Incompatible Gradle JVM version", tell them the one-click fix: click the **"Apply compatible Gradle JDK configuration and sync"** link in the sync error — Android Studio downloads a compatible JDK (e.g. 21) and re-syncs automatically. (Note: the embedded JBR may be 17 or 21 — both work with Gradle 8.9; the only thing to avoid is a standalone JDK 23/24/25. Also captured in the generated README and `couchbase-lite-android-app`.)

**This flow targets an emulator** — no signing config needed (a debug keystore is auto-generated); a Play Store release build is outside the default flow.

## Upfront questions

**Ask ONE question at a time — do not batch.** Wait for each answer before asking the next.

**The selection widget may render only option *labels*, not their `description`.** So don't rely on `description` to carry meaning. Instead, for any question where the choices aren't self-evident, **write the options and what each means as a short plain-text list in your message first**, then ask. (You may still call `AskUserQuestion` with short labels + `description` after that text — the text is what guarantees the user sees the explanation; also keep labels self-clarifying, e.g. `Admin-Assigns (manager assigns, user updates)`.)

Platform **is** the first question now — iOS or Android (established in the opening above). Ask these in order:

1. **Platform** — iOS (Swift) or Android (Kotlin)? Both build the same cloud-edge app; the choice selects the client capability (`couchbase-lite-ios-app` vs `couchbase-lite-android-app`) and the platform-specific prerequisites. Do **not** offer web/Flutter/etc. (not built yet).
2. **Capella account** — Do you already have a free Capella account? If not, share https://cloud.couchbase.com and pause until confirmed (needed to run `setup-capella.sh`).
3. **App domain** — What kind of data does the app manage? Give a few examples (field tasks, retail transactions, airline orders, inventory). Drives collection names, the assignee field, and sample data.
4. **Access pattern** — ask this AFTER the domain is known, tailored to it (see below).
5. **Project location** — the currently selected folder (default) or somewhere else? **Always ask — never assume the workspace folder.**

### The access-pattern question (step 3)

Frame it as an **access-control matrix in the user's domain nouns** — who can **read**, who can **create**, who can **update** (create and update are separate: e.g. a manager creates/assigns, the assignee updates). Write this as plain text in your message, then ask.

Substitution (replace `<user>`/`<records>` with the domain's nouns):

- **Admin-Assigns (default)** — Read: each `<user>` sees only their own `<records>`; admin sees all. Create: admin/manager (assigns to a `<user>`). Update: the assigned `<user>` (admin can edit/reassign/close any). Best when someone assigns work that individuals then own.
- **Team / Group** — Read: everyone on the team. Create: any team member (or restrict to a lead). Update: any team member. Admin oversees all teams. Best for a shared pool a crew works together.
- **Shared Read-Only** — Read: everyone. Create: admin only. Update: admin only. Reference material (checklists, catalogs, manuals) everyone reads but nobody else edits — usually an *add-on* to one of the above, not the model for the working records.

**Always recommend one, and say why in one line.** Default recommendation: **Admin-Assigns** — it fits most mobile/field apps (individuals own the work assigned to them) and exercises the full model. Recommend **Team/Group** instead only if the described workflow is clearly a shared pool a group works together with no per-person ownership. **Shared Read-Only** is an add-on, never the primary recommendation. Present the recommended option **first** and mark it **(Recommended)**; the user can still pick another.

Worked example — present it in your message exactly like this (domain = *inspections*, user = *inspector*, admin = *manager*), then ask the one question:

> **Which access pattern should govern the inspection records?**
>
> I'd recommend **Admin-Assigns** — inspections are usually assigned to and owned by an individual inspector.
>
> - **Admin-Assigns (Recommended)** — Manager creates an inspection and assigns it to an inspector; that inspector updates it; each inspector sees only their own; manager reads/edits all.
> - **Team / Group** — Any inspector on a team creates inspections; the whole team reads and updates them; manager oversees all teams.
> - **Shared Read-Only** — Manager creates and edits reference docs (checklists, standards); every inspector reads them but can't change them.
>
> Go with Admin-Assigns, or pick another? (1 Admin-Assigns · 2 Team/Group · 3 Shared Read-Only)

Then the `AskUserQuestion` labels can be short, recommended first — `Admin-Assigns (Recommended — manager assigns, inspector updates)`, `Team/Group (team shares)`, `Shared Read-Only (admin-authored reference)` — since the full explanation is already in the message text above.

Other domains map the same way (airline: the purser assigns meal-prep orders to cabin crew, each crew member updates their own, purser sees all; retail POS: a manager assigns restock/transaction tasks per store, each store updates its own, head office sees all) — always name the real actors, see "Domain parameterization" below. Patterns defined in `couchbase-mobile-concepts-patterns`; implemented by `couchbase-mobile-access-control-function`.

## Domain parameterization — map the roles to real people, and EXPLAIN them

The technical shape is identical across domains (Admin-Assigns: a manager creates/assigns records; each app user owns the ones assigned to them). What changes is the **cast**. **When you propose or adopt a domain, explain the cast and flow in plain language *before* generating — don't just swap field names.** Tell the user:

- **App users** — who signs in and owns records.
- **Manager (admin role)** — who creates/assigns work and sees everything.
- **Record (the "task")** — what they create and act on.
- **Flow** — manager creates & assigns → each app user sees only their own → they update it → manager sees the change live.

Examples (the `assignee` field holds the app user's identity):

| Domain | App users (who sign in) | Manager (admin role) | The record they work | collections |
|---|---|---|---|---|
| Field ops | field technicians | dispatcher / ops manager | a work task at a site | `tasks`, `resources` |
| Airline meal ordering | cabin crew | head of cabin crew (purser) | a meal-prep order (e.g. "prepare 40 veg meals on flight BA123") | `orders`, `menus` |
| Retail POS | store associates (or a per-store login) | store / head-office manager | a transaction or restock task | `transactions`, `inventory` |
| Warehouse | pickers | shift lead | a pick / put-away task | `stock`, `movements` |

Worked framing to say out loud (airline example): *"The app users are **cabin crew**; the **head of cabin crew (purser)** holds the manager role. The purser creates **meal-prep orders** — e.g. 'prepare 40 vegetarian meals on flight BA123' — and assigns each to a crew member. Each crew member signs in and sees only the orders assigned to them, and marks them prepared/served; the purser sees every order across the flight."* Do the equivalent for whatever domain the user picks (name the people, the manager, the record, and the create→assign→update→observe flow).

See `reference/adapting-domain.md`. The chosen collection names become the `COLLECTIONS` env var (provisioning), the access control function filenames (access-control), and the client's `AppConfig` constants — `AppConfig.swift` (iOS) or `AppConfig.kt` (Android) — keep all three consistent.

## Workflow

> **Backend provisioning is the long pole (~20–45 min).** Start it **early** so it runs *in parallel* while you generate the app — don't leave it to the end. The only blocker is that the script uploads the Access Control Functions, so the model + ACF files must exist first (quick). Sequence below reflects this.

1. Ask the upfront questions **one at a time**, in order (**platform: iOS or Android** — don't offer web/others → Capella account → domain → access pattern, tailored to the domain → project location). For non-obvious choices, put the explanation in your message text before asking, since the widget may not show option descriptions.

   > **⛔ MANDATORY GATE — confirm prerequisites BEFORE any modeling or file-writing. Do NOT skip or defer this; it is the single most-skipped step.** The moment the platform is known, run the **Prerequisites** section for that platform as its own explicit step: **ask the user their Xcode (iOS) / Android Studio (Android) version**, pin the matching Couchbase Lite version, **recommend upgrading if the toolchain is too old for the latest CBL (4.x)**, and confirm they have **two Simulators / emulators**. **Stop and wait for the user to confirm their toolchain version before you continue to step 2 (modeling).** A wrong or unknown toolchain version is the #1 cause of a broken first build — treat this as a hard stop, not a passing statement.
2. Model the data → `couchbase-mobile-concepts-patterns`.
3. **Actually write the Access Control Function file(s) to disk** → `couchbase-mobile-access-control-function`. Create **one `.js` per collection** in `COLLECTIONS`, named **exactly** `<collection>-sync-function.js` (e.g. `transactions/transactions-sync-function.js`), inside the project's `sync-functions/` folder. This is a real file-write, not a description — the provisioning script only *uploads* these files and **FATALs if any is missing** (`Access Control Function not found at: …`). Then copy `assets/setup-capella.sh` into the project (`chmod +x`) and generate `provision.env` from `assets/provision.env.example` with the app's `CB_ENDPOINT_NAME`, `COLLECTIONS`, a **unique `APPSVC_ADMIN_USER`** (e.g. `<endpoint>admin`, not `admin`), and **`SYNC_FUNCTIONS_DIR='sync-functions'`** (keep `setup-capella.sh` and the `sync-functions/` folder together in the project root — the script resolves this relative to its own location, so use just `sync-functions` with **no project-name prefix**).
   > **Pre-flight (do before any provisioning run):** for every entry in `COLLECTIONS`, confirm `"$SYNC_FUNCTIONS_DIR/<collection>-sync-function.js"` exists on disk. If `COLLECTIONS='retail/transactions retail/inventory'`, you must have `transactions-sync-function.js` AND `inventory-sync-function.js` in `SYNC_FUNCTIONS_DIR`. Do **not** start provisioning until all exist.
4. **Offer to start backend provisioning now** (it's long-running — kicking it off now lets it run while you build the app). **First confirm the pre-flight above passes.** Then ask **one question**: *Start the backend now (recommended — ~20–45 min, runs in parallel while I generate the app) or later (after the app is generated)?*
   - **If now:** guide the user to create a Capella API key (Organization Owner: in the Capella UI, select your Organization, then Settings, API Keys, Generate Key; leave other roles/expiry/IP at defaults), then **hand them the numbered steps to run provisioning themselves** -- Claude does **not** run `setup-capella.sh` and never asks for the API key. In order: (1) **copy or download** the key -- it's shown only once in the UI, so download it to be safe; (2) copy the **`APIKeyToken`** value from the downloaded file (= **API Secret** in the UI) and paste it into `CB_API_KEY` in `provision.env` (already in the project with the app values filled); (3) run `source provision.env && ./setup-capella.sh` from the project folder; (4) tell you when the App Endpoint is Online. Their key stays on their machine. Then proceed to step 5 and build the app while they provision.
   - **If later:** continue; do the same provisioning step after the app is generated (step 6).
5. **Generate the client app** → the client capability **for the chosen platform**: `couchbase-lite-ios-app` (iOS) or `couchbase-lite-android-app` (Android). You already confirmed the toolchain version, the pinned CBL version, and the prerequisites at the **step-1 gate** — **if for any reason you did not, do it now before generating** (confirm Xcode / Android Studio version, pin the matching CBL, suggest upgrading if too old, confirm two Simulators/emulators). If a prerequisite is missing, pause and direct the user to install before continuing. This runs during the provisioning wait if you started it in step 4.
6. **If provisioning was deferred**, hand the user the run-it-yourself steps now (same key-creation and run flow as step 4).
7. **Offer seed/demo data — MANDATORY, do not skip.** Once the endpoint is Online you **must ask** (as its own one-question prompt) whether the user wants a couple of demo documents so the two-simulator test shows data immediately (e.g. one record assigned to `bob` + one shared reference). This is easy to skip when provisioning ran in the background — don't. Only create on a yes; announce exactly what you're writing, label test/verification docs (`zz-test-…`), and say how to remove them. Never write documents to their backend silently. See `couchbase-appservices-provisioning` → "Seed / test data".
8. **Generate `README.md`** in the project with the full run sequence (see below) — the durable reference.
9. **Hand off with the explicit message** below — then point to the two-simulator offline test in `couchbase-lite-ios-app`. If provisioning is still running, say you'll confirm when the App Endpoint is Online.

**Before you consider the build done, confirm you did all of these — don't skip any:**
- [ ] **Confirmed the toolchain version + prerequisites at the step-1 gate, BEFORE modeling** — the most-skipped step; a wrong/unknown Xcode/Android Studio version breaks the first build
- [ ] Wrote the access control function `.js` file(s) and passed the pre-flight check (step 3)
- [ ] Handed the user the run-it-yourself provisioning steps -- never ran the script for them (step 4/6)
- [ ] Generated the client app (step 5)
- [ ] **Asked about seed/demo data** (step 7) — this is the one most often missed
- [ ] Generated `README.md` (step 8)
- [ ] Gave the explicit, path-specific hand-off (step 9)

## README.md (always generate one)

Write a `README.md` at the project root containing, in order: (a) what the app is + the chosen access pattern; (b) **Backend setup** — the exact `provision.env` + `source provision.env && ./setup-capella.sh` steps and what the script does (20–45 min, provisions cluster→endpoint, creates users, and writes the WSS URL into the client config — iOS `Info.plist`, or Android `local.properties`); (c) **Run the app** and (e) the **two-device offline test**, written out for the chosen platform; (d) default logins. Tailor (c) and (e) to the platform:

- **iOS:** Run — resolve packages, pick a Simulator, Cmd+R (signing only for a physical device). Two-simulator test — **(1)** Cmd+R on Sim 1, sign in as manager; **(2)** Stop the run in Xcode; **(3)** switch destination to Sim 2, Cmd+R, sign in as bob; **(4)** tap the app icon on Sim 1 to relaunch it standalone. Mirror `couchbase-lite-ios-app/reference/testing-offline-sync.md` (note `Cmd+B` does not install to a simulator).
- **Android:** Run — open the ROOT project folder (File → Open → the `<AppName>` folder with `settings.gradle.kts`) in Android Studio; **set the Gradle JVM to 17** (one-time; new Android Studio may default it to JDK 24/25, which the bundled Gradle 8.9 wrapper cannot run): Settings/Preferences -> Build, Execution, Deployment -> Build Tools -> Gradle, set **Gradle JVM** / **Default Gradle JVM criteria -> Version** to **17** (the embedded JBR) and Apply; then Gradle sync, pick/create an emulator, Run ▶ (re-sync Gradle after the script writes `local.properties`). Two-emulator test — start both emulators, then in the device dropdown click **Select Multiple Devices…**, tick both, **Run ▶ once** to deploy to all at once (or run one target at a time); sign in independently (manager on one, bob on the other — the app always starts at Login, storage is per-emulator). Use two SEPARATE AVDs, not a Duplicate. Mirror `couchbase-lite-android-app/reference/testing-offline-sync.md`.

This is the durable reference; the hand-off message summarizes it.

## Hand-off message (final — be specific, NEVER vague)

Name real paths; never say "run the script somewhere." Include:

1. **What was generated & where** — the client project path (an **Xcode project** for iOS, or a **Gradle project** for Android), `sync-functions/`, `setup-capella.sh`, `provision.env`, `README.md`.
2. **Backend -- the user runs it themselves** (Claude never runs it; the API key stays on their machine). Present the steps as a **numbered list in the order performed** -- create the key in the Capella UI *first* (it's not in the project folder), *then* edit the file, *then* run:
     1. **Create a Capella API key** (in the Capella web console):
        - Select your **Organization**, then **Settings → API Keys → Generate Key**
        - Enter a **Key Name**
        - Under **Organization Roles**, check **Organization Owner** — leave the other roles, the 180-day expiration, and Allowed IP Addresses at their defaults
        - Click **Generate**, then **copy or download the key** (it's shown only once in the UI, so download it to be safe)
     2. **Open `provision.env`** in the `<project>/` folder and:
        - open the downloaded key file and copy the **`APIKeyToken`** value (shown as **API Secret** in the Capella UI) into `CB_API_KEY=''`
        - optionally change `APPSVC_ADMIN_PASS` (preset `Password1!` for dev)
        - (app values — endpoint, collections, `SYNC_FUNCTIONS_DIR` — are already filled in)
     3. **Run:** `source provision.env && ./setup-capella.sh` (20–45 min; writes the WSS URL into the client config — iOS `Info.plist` / Android `local.properties`; creates logins `manager` / `bob`, `Password1!`).
     4. **Tell me when the App Endpoint is Online.** (The script creates default logins `manager` / `Password1!` (admin) and `bob` / `Password1!` (regular).)
3. **Client — what the user does:**
   - *iOS:* open the `.xcodeproj`, File → Packages → Resolve Package Versions, pick a **Simulator**, then **Cmd+R** to build & run. *(No signing needed for the simulator.)*
   - *Android:* open the ROOT `<AppName>` folder (File → Open → the folder with `settings.gradle.kts`) in **Android Studio** — if it prompts for the Android SDK, install it via the SDK Manager (see `couchbase-lite-android-app`) — let Gradle sync, pick/create an **emulator**, then Run ▶. **Re-sync Gradle** after the script writes `local.properties` so `BuildConfig` picks up the URL.
   Can happen while provisioning finishes.
4. **Seed data:** state whether you created demo docs (and which, labeled) or that the user declined — i.e. confirm step 7 actually happened. If provisioning was still running when you asked earlier, ask now that it's Online.
5. **Offline test:** the two-device procedure — see `couchbase-lite-ios-app` (two simulators) or `couchbase-lite-android-app` (two emulators) for the chosen platform.

Example shape — **iOS** (you ran it): "Generated `InspectionsApp/` (Xcode project), `InspectionsApp/sync-functions/inspections-sync-function.js`, `setup-capella.sh`, and `provision.env`. I've kicked off provisioning with your API key — it's running now (~20–45 min) and I'll confirm when the `inspections` endpoint is Online; it also writes the sync URL into your `Info.plist`. Meanwhile: open the project, resolve packages, pick a Simulator, and Cmd+R to build & run (no signing needed for the simulator). Sign in as `bob`/`Password1!` (or `manager` for admin). Full sequence is in `README.md`."

Example shape — **Android** (analogous): "Generated `InspectionsApp/` (Gradle project), `InspectionsApp/sync-functions/inspections-sync-function.js`, `setup-capella.sh`, and `provision.env`. Provisioning is running (~20–45 min); it also writes the sync URL into `local.properties`. Meanwhile: open the project in Android Studio, let Gradle sync, and Run ▶ onto an emulator — **re-sync Gradle after the script finishes** so `BuildConfig` picks up the URL. Sign in as `bob`/`Password1!` (or `manager` for admin). Full sequence is in `README.md`."

## Reference material

- `reference/reference-implementation.md` — the public Couchbase Retail Demo (the reference app to adapt) plus the in-skill comprehensive access model that fills the Retail Demo's access-control gap.
- `reference/adapting-domain.md` — how to retarget to a new domain.
- `reference/troubleshooting.md` — common errors across backend and client.
- `reference/key-design-principles.md` — the guiding principles for the whole build.

## Presenting steps to the user

Whenever you give the user multi-step instructions, format them as a **numbered list — one action per line** (use sub-bullets for details), never a dense paragraph. List the steps in the **order the user performs them**: actions done in an external UI (e.g. creating a Capella API key in the web console) come *before* actions in the project folder (editing files, running commands). Applies to every skill here, so the experience is consistent for the whole team. **When a step means changing a setting inside an app (e.g. Android Studio's Gradle JVM, an Xcode build setting), spell out the click path in your reply -- the menu, the field, the value to pick, and Apply -- right where you raise it. Never just name the setting, say "set it to X", or tell the user to "see the README"; the generated README is a durable copy, not a substitute for telling the user how to change it, now.**
