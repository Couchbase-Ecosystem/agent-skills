## How to Test Offline-First Sync — Two Simulators

Run the app on **two iOS Simulators** simultaneously (this is the default target — most people don't have two physical devices; a physical device is optional and needs code signing). Requires `CouchbaseLiteSwift.framework` to be properly embedded in the app bundle (see project.pbxproj rules above).

> **Need two INDEPENDENT simulators (required to sign in as different users):** Xcode → **Window → Devices and Simulators → Simulators → +** and add a second model (e.g. iPhone 16 *and* iPhone 16 Pro). Each simulator has its **own isolated storage**, so each shows its own Login screen and can sign in as a different App User.
>
> The app **always starts at the Login screen** on a fresh launch (no auto-login). If a simulator you're reusing still carries an old session, reset it: Simulator app → **Device → Erase All Content and Settings**, then sign in fresh.

### What each simulator represents (tailor to the access pattern)

Sign the two instances in as **different users** so access control and sync are visible. Who each represents depends on the app's access pattern — explain this to the user before they start:

- **Admin-Assigns (default):** Sim 1 = the **admin/manager** (creates records and assigns them); Sim 2 = a **regular user** = the assignee (sees only their own records; updates them). You'll demonstrate: manager creates & assigns → the record appears on the assignee's device → assignee updates it → manager sees the change. A record assigned to someone else must **not** appear for this user.
- **Team / Group:** both sims = **members of the same team** — both see and edit the shared pool. (Optionally add a third sim as a *different* team's member to show that teams are isolated.)
- **Shared Read-Only:** Sim 1 = **admin** (creates/edits the reference docs); Sim 2 = **regular user** (receives them automatically, read-only — attempts to edit are rejected).

Use the default logins created by provisioning — `manager` / `Password1!` (admin) and `bob` / `Password1!` (regular) — unless you created others. Substitute the domain's nouns for "record" (task, inspection, transaction, order…).

### Running on two simulators — the reliable procedure (this is fiddly; follow the order exactly)

**Why it's tricky:** Xcode builds/runs/debugs only **one** destination at a time. When you run the *second* simulator, Xcode **ends its session on the first** (the app there is killed — you'll see `Message from debugger: killed`). So you bring the first app back by **tapping its icon** — a **standalone launch** with no Xcode attached. That only works because the CouchbaseLite framework is embedded in the app bundle; if embedding is missing, tapping the icon crashes with `Library not loaded: CouchbaseLiteSwift.framework` (the "won't launch unless Xcode is attached" symptom). Confirm the embedding fix is in place first: `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")` + the empty Embed Frameworks phase (see `installation-and-plist.md` / project.pbxproj rules).

1. **Build & run on Simulator 1 from Xcode.** Set the run destination to Simulator 1 → **Cmd+R**. **Confirm the app actually launches on Simulator 1**, then sign in as `manager` / `Password1!`. *(When you run the app, ignore any "Signing for … requires a development team" warning — signing is only needed for a physical device; the app runs on the Simulator without it.)*
2. **Stop the run in Xcode.** Click **Stop (■)** (or **Cmd+.**). The app on Simulator 1 is killed (`Message from debugger: killed` in the console) but stays **installed**.
3. **Select Simulator 2 and build & run.** Change Xcode's run destination to Simulator 2 → **Cmd+R**. Sign in as `bob` / `Password1!`.
4. **Launch the app on Simulator 1 by tapping its icon** on the home screen. It runs **standalone** (Xcode is now attached to Simulator 2). Both apps are now live side by side.

> `Cmd+B` only compiles — it does **not** install or launch on a simulator. Use `Cmd+R` per destination, then the icon-tap to bring Simulator 1's app back.

### What to do on each app

Drive the two apps to see access control + sync live. This is the **Admin-Assigns** example (adapt to your access pattern and domain nouns):

- **Simulator 1 — `manager` (admin):** tap **+**, create a record, and assign it to `bob`. The manager can see and edit *all* records.
- **Simulator 2 — `bob` (regular user):** you see *only* records assigned to you. Open one and change its status / add notes.
- **Watch it sync:** the record the manager assigns appears on bob's device within a second or two; when bob updates the status, the manager sees the change live. A record assigned to someone else must **not** appear for bob.

### Test offline-first

1. Turn off Wi-Fi on either simulator: **Settings → Wi-Fi → off**
2. Make changes — saved instantly to local database, sync indicator shows "Offline"
3. Turn Wi-Fi back on — changes sync automatically

### Troubleshooting

**First step for any sync issue: check the Xcode console.** Filter by **"CouchbaseLite"** — verbose logging shows every replication event, auth handshake, and document push/pull. This is the fastest way to diagnose what's happening.

**App crashes on home screen tap**
`CouchbaseLiteSwift.framework` is not embedded. Ensure `PBXCopyFilesBuildPhase` for Embed Frameworks is in the project + `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")` in build settings. Then Cmd+Shift+K and rebuild.

**HTTP 403 `sg missing channel access` on push**
This means the ACF isn't routing the document to any channel the pusher has access to. Most common cause: **the ACF was never deployed** — the script fell back to the passthrough default `function(doc, oldDoc){ channel(doc.channels); }` because the sync function file wasn't found. Documents from this app have no `channels` field, so they get routed to no channel → every push is rejected with 403.

Check immediately:
1. In Capella UI → App Services → App Endpoint → the collection → Access Control. The function should be your custom ACF. If it shows `function(doc, oldDoc){ channel(doc.channels); }`, it was never deployed.
2. Fix: ensure the sync function file is in `sync-functions/<collection>-sync-function.js` next to `setup-capella.sh`, then re-run the script.
3. Keep `setup-capella.sh` and the `sync-functions/` folder **together** (both in the project root), and set `SYNC_FUNCTIONS_DIR='sync-functions'`. The script resolves that path **relative to its own location**, so it works regardless of where you run it from and needs **no project-name prefix**. (If you see `Access Control Function not found`, the script prints the resolved path — check the `.js` files are actually in that folder, named `<collection>-sync-function.js`.)

**Document created but doesn't appear on the other device**
Work through this in order:
1. Check console for CBL errors — look for `401 Unauthorized`, `404 Not Found`, `403`, or `access denied`
2. **403 / sg missing channel access**: ACF not deployed — see above
3. **401 Unauthorized**: App User credentials wrong. Verify username/password match exactly what was created in App Services → App Users
4. **404 Not Found**: WSS URL in Info.plist wrong or App Endpoint is Offline. Go to Capella → App Services → App Endpoint and confirm it shows "Online"
5. **Wrong scope/collection**: App Services collection name must exactly match `AppConfig.scopeName` / `AppConfig.<collection>`. Never use `_default` scope.
6. **Document missing `assignee` field**: If ACF does `channel(doc.assignee)` but `assignee` is empty, doc routes to channel `""` — no one receives it. Always set `assignee` on create.

**Sync indicator stuck on "Connecting"**
WSS URL in Info.plist must match the App Endpoint URL exactly — copy it from Capella → App Services → App Endpoint → Connect → WebSocket URL.

**Sync indicator shows error (red)**
Open Settings in the app — the error message and hint are shown there. 401 = auth issue, 404 = endpoint/URL issue.

**Replicator starts but no documents pull down**
The user has no documents routed to their channel. For admin-assigns pattern: manager must create a document AND set the `assignee` field to the other user's username. The ACF routes it to `channel(assignee)` — if assignee is empty or wrong, the doc never reaches the other user.

**ACF dry run — do this before debugging the app**

When a document isn't syncing, trace it manually through the Access Control Function with a sample document. Show the user this trace so they can verify the routing is correct before touching the app or the replicator.

Example for the admin-assigns pattern with a sample todo document:

```
Sample document being pushed by manager:
{
  "_id": "todo::001",
  "title": "Fix the generator",
  "assignee": "bob",
  "status": "todo",
  "notes": ""
}

Dry run through ACF:
1. channel("bob")    → document routed to channel "bob"
2. channel("admin")  → document also routed to channel "admin"
3. access("bob", "bob")   → user "bob" granted access to channel "bob"  ✓ bob will receive this doc
4. manager has admin_channels: ["admin"] inherited from the admin App Role → ✓ manager will receive this doc
5. requireRole("admin") on create (oldDoc is null) → manager has admin role → PASS ✓

Note: there is NO access("role:admin", ...) call — that does NOT work in App Services ACFs. Admin channel
access is always granted via admin_channels in the Admin REST API, not via access() in the ACF.

Result: document syncs to bob and manager. ✓

Now trace a broken case — assignee field is empty:
{
  "_id": "todo::002",
  "title": "Fix the pump",
  "assignee": "",       ← empty!
  "status": "todo"
}

1. channel("")   → routes to channel "" (empty string — no user has this channel)
2. channel("admin") → routes to admin channel ✓
3. access("", "") → grants "" user access to "" channel — meaningless
4. manager still has admin_channels: ["admin"] → admin receives this doc ✓

Result: only admin receives this document. bob never sees it. ✗
Fix: always require assignee before saving — guard in the UI and in the ACF.
```

Always do this dry run first when a document isn't syncing. It immediately shows whether the problem is the ACF routing, a missing field, or something else entirely. Present this trace to the user so they understand why the document is or isn't being routed correctly.

---

