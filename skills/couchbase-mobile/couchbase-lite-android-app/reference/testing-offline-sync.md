## How to Test Offline-First Sync — Two Emulators

Run the app on **two Android emulators** simultaneously to see access control and sync live. Unlike Xcode, Android Studio can run and keep **both** emulators active at once (each is a separate deployment target), so this is a little less fiddly than the iOS two-simulator dance.

> **Need two INDEPENDENT emulators (required to sign in as different users):** create **two SEPARATE AVDs** — Device Manager → **Create Virtual Device** (e.g. a Pixel 8 *and* a Pixel 8 Pro, API 35). Do **NOT** use **Duplicate**: a duplicated AVD copies the first device's saved data, so it comes up already logged in as the same user. Two separate AVDs each have isolated storage, so each shows its own Login screen and can sign in as a different App User.
>
> The app **always starts at the Login screen** on a fresh launch (no auto-login). If an emulator you're *reusing* comes up already logged in from an earlier test, tap **Sign Out** (bottom of Settings) or reset it via Device Manager → **⋮ → Wipe Data**, then sign in fresh.

### What each emulator represents (tailor to the access pattern)

Sign the two instances in as **different users** so access control and sync are visible. Who each represents depends on the app's access pattern — explain this before starting:

- **Admin-Assigns (default):** Emulator 1 = the **admin/manager** (creates records and assigns them); Emulator 2 = a **regular user** = the assignee (sees only their own records; updates them). Demonstrate: manager creates & assigns → the record appears on the assignee's device → assignee updates it → manager sees the change. A record assigned to someone else must **not** appear for this user.
- **Team / Group:** both emulators = **members of the same team** — both see and edit the shared pool.
- **Shared Read-Only:** Emulator 1 = **admin** (creates/edits reference docs); Emulator 2 = **regular user** (receives them automatically, read-only).

Use the logins created by provisioning — run `grep -E "MANAGER_PASS|BOB_PASS" provision.env` in the project folder to get the actual values (defaults are `Password1!` for both unless you customized them) — unless you created others.

### Creating and starting the emulators (from scratch — every click)

New to Android Studio? Here is the whole path from nothing to two running emulators.

**Open Device Manager.** Look at the narrow **icon strip on the right edge** of the Android Studio window and click the **phone icon** (hover tooltip: *Device Manager*). Can't find it? Use the menu: **View → Tool Windows → Device Manager**. A panel opens listing your virtual devices — it may be empty the first time.

**Create the first emulator** (an "AVD" = Android Virtual Device):

1. In the Device Manager panel click **＋** (top of the panel) → **Create Virtual Device…** (older UIs: a **Create device** button).
2. **Choose hardware** — pick a phone, e.g. **Pixel 8** → **Next**.
3. **Choose the system image** (the Android version) — select **API 35** (Android 15). If its name shows a **⬇ download** icon, click it, accept the license, wait for it to finish, then select it → **Next**.
4. **Name it** something recognizable, e.g. `Pixel8_API35` → **Finish**. It now appears in the Device Manager list.

**Create a SECOND, separate emulator** — repeat steps 1–4 but pick a **different phone** (e.g. **Pixel 8 Pro**) and a **different name** (e.g. `Pixel8Pro_API35`). ⚠️ Do **NOT** use **⋮ → Duplicate** on the first device — a duplicate copies its saved data, so it boots already logged in as the same user. Two devices you create separately each get their own clean storage.

**Start both emulators.** In the Device Manager list, click the **▶ (Play)** button on each device's row. An emulator window opens for each; **wait until it finishes booting to the Android home screen** (first boot can take a minute or two). Leave both windows running.

You now have two independent, running emulators — they will appear as run targets in the next step.

### Running on two emulators — the procedure

**Fastest — deploy to all at once with "Select Multiple Devices":**

1. **Make sure both emulators are running** — booted to the Android home screen (see *Creating and starting the emulators* just above; click **▶** on each device in Device Manager). Only running emulators appear as run targets.
2. In the **target/device dropdown** at the top (next to the green Run ▶ — it normally shows one device name), click **Select Multiple Devices…**. Tick the emulators you want (two or more) → **OK**. The dropdown now reads **"Multiple Devices (N)"**.
3. Click **Run ▶ once.** Android Studio builds once and installs + launches the app on **all** selected devices simultaneously.
4. **Sign in independently on each device** — `manager` on one, `bob` on the other (run `grep -E "MANAGER_PASS|BOB_PASS" provision.env` in the project folder for the actual passwords — default `Password1!` for both unless customized). The app always starts at Login and each emulator has its own storage, so the two sessions are fully independent.

> If the dropdown doesn't list a device, it isn't running yet — start it in Device Manager (▶) and reopen the dropdown. "Select Multiple Devices…" only shows **running** emulators (and connected physical devices).

*Alternative (one target at a time):* pick a single emulator in the dropdown → Run ▶ → sign in as `manager`; then change the dropdown to the other emulator → Run ▶ again (the first app keeps running) → sign in as `bob`.

> `./gradlew assembleDebug` only builds the APK — it does not install. Use Run ▶ per target, or `adb -s <emulator-id> install -r app/build/outputs/apk/debug/app-debug.apk` to install onto a specific emulator (`adb devices` lists their ids).

### What to do on each app (Admin-Assigns example — adapt to your pattern/domain)

- **Emulator 1 — `manager` (admin):** tap **+**, create a record, assign it to `bob`. The manager sees and edits *all* records.
- **Emulator 2 — `bob` (regular user):** you see *only* records assigned to you. Open one and change its status / add notes.
- **Watch it sync:** the record the manager assigns appears on bob's device within a second or two; when bob updates it, the manager sees the change live. A record assigned to someone else must **not** appear for bob.

### Test offline-first

Two ways to simulate offline:

1. **In-app (preferred):** open **Settings → Offline-First Demo** toggle. This pauses the replicator — edits still save to the local database instantly and the sync indicator shows "Offline". Toggle back on and pending changes sync immediately. (No network config needed — this is the offline-first demo in one switch.)
2. **Emulator network:** extended controls (`•••`) → **Cellular/Wi-Fi → data off**, or toggle Airplane mode. Make changes, then restore the network — changes sync automatically.

### Troubleshooting

**First step for any sync issue: check Logcat.** Filter by **"CouchbaseLite"** — verbose logging (enabled in `Application.onCreate` for debug) shows every replication event, auth handshake, and document push/pull. Fastest way to see what's happening.

**Build fails: "unresolved reference: APP_SERVICES_ENDPOINT_URL"**
`buildFeatures { buildConfig = true }` is missing, or `cbl.endpointUrl` isn't in `local.properties` yet. Add the flag / run `setup-capella.sh`, then re-sync Gradle.

**Replication fails / "APP_SERVICES_ENDPOINT_URL not set" at runtime**
The script hasn't written the real URL, or Gradle wasn't re-synced after it did. Run `setup-capella.sh`, then Gradle sync so `BuildConfig` regenerates.

**HTTP 401 Unauthorized**
App User credentials wrong. Verify username/password match an App User created in App Services (`manager` / `bob`).

**HTTP 404 / connection error / stuck on "Connecting"**
WSS URL wrong or the App Endpoint is Offline. Confirm `cbl.endpointUrl` matches Capella → App Services → App Endpoint → Connect → WebSocket URL, and that the endpoint shows **Online**.

**HTTP 403 `sg missing channel access` on push**
The Access Control Function isn't routing the document to a channel the pusher can access — usually the ACF was never deployed (the script fell back to the passthrough default). Check Capella UI → App Endpoint → collection → Access Control shows your custom function; if not, ensure `sync-functions/<collection>-sync-function.js` exists next to `setup-capella.sh` and re-run it.

**Document created but doesn't appear on the other device**
1. Logcat for `401`/`404`/`403`/`access denied`.
2. **403** → ACF not deployed (above).
3. **Wrong scope/collection** → App Services collection name must exactly match `AppConfig.scopeName` / `AppConfig.<collection>`; never `_default`.
4. **Missing `assignee`** → if the ACF does `channel(assignee)` but `assignee` is empty, the doc routes to channel `""` and no one receives it. Always set `assignee` on create.

**ACF dry run — do this before debugging the app.** Trace the document manually through the Access Control Function (see the iOS skill's `testing-offline-sync.md` or `couchbase-mobile-access-control-function`): `channel(assignee)` + `channel("admin")`, `access(assignee, assignee)`, `requireRole("admin")` on create. It immediately shows whether the problem is routing, a missing field, or something else. The ACF logic is identical for Android and iOS clients — only the client platform differs.

---
