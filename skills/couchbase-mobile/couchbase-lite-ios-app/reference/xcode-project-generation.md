## Generating the Xcode Project (REQUIRED — do this automatically)

**Never ask the user to create the Xcode project manually.** Generate the complete `.xcodeproj` yourself.

> 📖 **Reference repository for build and package settings (use this when in doubt):**
> https://github.com/couchbase-examples/couchbase-lite-retail-demo
>
> This official Couchbase example covers iOS, Android, and other languages. The iOS project (`/iOS`) is the verified reference for:
> - Correct `project.pbxproj` structure for CouchbaseLiteSwift via SPM
> - Required build settings (`LD_RUNPATH_SEARCH_PATHS`, `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`)
> - Correct empty `Embed Frameworks` phase for SPM XCFrameworks
> - Package URL and version configuration
>
> When a build setting question arises, **check this repo first** before guessing.

**MANDATORY CODE GENERATION RULES — apply to every Swift file you write:**

0. **Use current Couchbase Lite 4.x APIs — NEVER a deprecated or removed one.** Before emitting any CBL call, confirm it against (a) the **reference app** (couchbase-examples/couchbase-lite-retail-demo `/iOS` — targets CBL 4.1.0 and is the ground truth for how the current API is actually used) and (b) the **official API docs** at https://docs.couchbase.com/couchbase-lite/current/swift/ (and the versioned API reference at https://docs.couchbase.com/mobile/4.1.0/couchbase-lite-swift/). When in doubt, fetch the docs — do NOT emit an API from memory. **Compatibility floor:** generated code must COMPILE across the full supported CBL range — currently **3.3.x through 4.x** — so never use an API introduced after the floor. **Logging:** use `LogSinks.console = ConsoleLogSink(level: .verbose, domains: .all)` — the `LogSinks` API spans **3.3.x through 4.x**; do NOT use the old `Database.log.console` (removed in 4.0). CRUD is collection-based (`collection.document(id:)`, `collection.save(...)`). **Replication:** `ReplicatorConfiguration(collections: [CollectionConfiguration(collection: c1), …], target: target)` then set `replicatorType`/`continuous`/`authenticator` — the `ReplicatorConfiguration(target:)` + `config.addCollection(...)` forms were REMOVED in 4.0 (verified against the reference `/iOS` app). If a snippet in this skill ever fails to compile against 4.x, treat it as a skill bug: fix it against the docs + reference app.


1. **Toolbar: always declare exactly TWO `ToolbarItem`s.** A single `ToolbarItem` in `.toolbar {}` always causes `Ambiguous use of 'toolbar(content:)'`. No exceptions.
   - List views: `ToolbarItem(.topBarLeading)` + `ToolbarItem(.topBarTrailing)`
   - Modal sheets (detail, settings, any sheet): `ToolbarItem(.topBarLeading)` + `ToolbarItem(.topBarTrailing)`
   - Use `if condition { ToolbarItem(...) }` for a conditional second item — the conditional still resolves the type

2. **`onChange` — use iOS 16-compatible single-parameter form.** The two-parameter `{ _, newValue in }` form is iOS 17+ only. On iOS 16 target it causes a cascading compile error that often surfaces as a confusing toolbar ambiguity on a different line.
   ```swift
   // ✅ iOS 16+ compatible
   .onChange(of: value) { newValue in ... }
   // ❌ iOS 17+ only — causes cascade errors on iOS 16 target
   .onChange(of: value) { _, newValue in ... }
   ```
   **For toggle actions that need to call manager methods, prefer `Binding(get:set:)` over `.onChange`** — cleaner and avoids the deprecated API entirely (see Rule 8 below).

3. **CBL console logging — enable in DEBUG in the App entry point** so sync failures are visible. Add to the `App` struct's `init()`:
   ```swift
   import CouchbaseLiteSwift

   init() {
       #if DEBUG
       // LogSinks: the current logging API, present across 3.3.x–4.x (the old
       // Database.log.console was removed in 4.0). `LogSinks.console` is a static property.
       LogSinks.console = ConsoleLogSink(level: .verbose, domains: .all)
       #endif
   }
   ```
   Tell the user: filter the Xcode console by **"CouchbaseLite"** to see all replication, auth, and sync activity.

   > ⚠️ **Logging API — use `LogSinks` (cross-version 3.3.x–4.x).** The old `Database.log.console` was **removed in 4.0**; `LogSinks.console = ConsoleLogSink(level: .verbose, domains: .all)` works across the supported range. Ref: https://docs.couchbase.com/mobile/4.1.0/couchbase-lite-swift/Classes/LogSinks.html

4. **`@MainActor` on every `ObservableObject`** class that holds `@Published` properties.

5. **Keychain for all credentials** — never `UserDefaults`. Store the password on login; the in-session Reconnect uses it (nil → force re-login). Always use single quotes when exporting passwords in bash (avoids `!` expansion).

5a. **ALWAYS show the Login screen on cold start — NO silent auto-login.** The app root must NOT auto-restore a session from the Keychain on launch (don't flip `isLoggedIn = true` from stored creds in `App.init`/`.onAppear`). Offline-first comes from the **local Couchbase Lite database persisting on disk** (data is there after re-login; sync resumes) — NOT from skipping Login. Keeps two-simulator multi-user testing clean: each simulator shows Login and signs in as its own App User.
   ```swift
   // Save on login
   KeychainHelper.save(password: password, for: username)
   // Retrieve for reconnect (nil if Keychain wiped)
   guard let password = authState.storedPassword, !password.isEmpty else {
       authState.logout(); return  // force re-login
   }
   ```

6. **`[weak self]` in all CBL callbacks** — live query and replicator listeners.

7. **Named scope only** — never `_default`.

8. **Offline mode toggle — use `ReplicationManager.pause()`, NOT `stop()`, and bind to singleton state.**

   The `ReplicationManager` must have two distinct methods:
   - `pause()` — user-initiated offline simulation. Sets `isManuallyPaused = true`, stops the replicator, sets `syncStatus = .offline`. Does NOT clear `isManuallyPaused` on resume — that's done by `start()`.
   - `stop()` — logout/cleanup only. Clears `isManuallyPaused = false`, stops replicator, sets `syncStatus = .idle`.

   ```swift
   @Published private(set) var isManuallyPaused: Bool = false

   func pause() {
       isManuallyPaused = true
       statusToken = nil
       replicator?.stop()
       replicator = nil
       syncStatus = .offline   // show offline indicator, not "Up to date"
   }

   func stop() {               // logout / cleanup
       isManuallyPaused = false
       statusToken = nil
       replicator?.stop()
       replicator = nil
       syncStatus = .idle
   }

   func start(...) throws {
       isManuallyPaused = false   // clear pause state on reconnect
       stop()                      // prevent duplicates
       // ... create and start replicator
   }
   ```

   **The Settings toggle MUST bind to `replication.isManuallyPaused` via `Binding(get:set:)` — NOT `@State` local state.**

   `@State private var simulatingOffline` resets to `false` every time the Settings sheet is dismissed and reopened. The replicator stays stopped but the toggle shows "Online" — the user has no way back. Use singleton state instead:

   ```swift
   // ✅ CORRECT — singleton state persists across sheet open/close
   Toggle(isOn: Binding(
       get: { replication.isManuallyPaused },
       set: { paused in
           if paused { replication.pause() } else { reconnect() }
       }
   )) { ... }

   // ❌ WRONG — @State resets on sheet dismiss, toggle shows "Online" while replicator is stopped
   @State private var simulatingOffline = false
   Toggle(isOn: $simulatingOffline) { ... }
   .onChange(of: simulatingOffline) { offline in ... }
   ```

9. **Always generate a `SettingsView`** — it is essential for debugging sync in any Couchbase Mobile app. A settings sheet must include:
   - Signed-in username and role
   - Sync status (with icon color: green=idle, blue=syncing, orange=connecting, grey=offline, red=error)
   - Last sync error message with hints (401 → check credentials; network error → check WSS URL)
   - Endpoint URL (selectable text — for copy-paste debugging)
   - Scope and collection names
   - Local document count
   - **Offline-First Demo toggle** (binds to `replication.isManuallyPaused` — see Rule 8)
   - Reconnect button
   - Sign Out button (destructive) — the view must be a scrolling `Form`/`List` (not a plain `VStack`) so Sign Out is never clipped; pin it prominently with `.safeAreaInset(edge: .bottom)` if the content is long

   The reconnect function guards against nil Keychain (forces re-login) and swallows only `collectionUnavailable` errors (auth failures surface asynchronously via the status listener):
   ```swift
   private func reconnect() {
       guard let db = DatabaseManager.shared.database else { return }
       guard let password = authState.storedPassword, !password.isEmpty else {
           authState.logout(); dismiss(); return
       }
       try? ReplicationManager.shared.start(username: authState.username,
                                            password: password, database: db)
   }
   ```

The project structure to generate:

```
<AppName>/
├── <AppName>.xcodeproj/
│   ├── project.pbxproj                        ← generate this
│   └── project.xcworkspace/
│       ├── contents.xcworkspacedata            ← generate this
│       └── xcshareddata/swiftpm/               ← directory only (SPM resolves on open)
└── <AppName>/
    ├── App/
    │   ├── <AppName>App.swift
    │   └── AppConfig.swift
    ├── Models/
    │   └── <Model>.swift
    ├── Database/
    │   ├── DatabaseManager.swift
    │   └── ReplicationManager.swift
    ├── Views/
    │   ├── LoginView.swift
    │   ├── <Domain>ListView.swift
    │   ├── <Domain>DetailView.swift
    │   └── SettingsView.swift          ← always include (sync status, offline toggle, diagnostics)
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   ├── AppIcon.appiconset/Contents.json
    │   └── AccentColor.colorset/Contents.json
    ├── Info.plist                      ← holds AppServicesEndpointURL (do NOT add a separate Config.plist)
    └── PrivacyInfo.xcprivacy           ← minimal privacy manifest (iOS 17+)
```

### Info.plist — required keys (never omit these)

When generating `Info.plist` with `GENERATE_INFOPLIST_FILE = NO`, these keys are **mandatory** — missing any causes "Bundle has missing or invalid CFBundleExecutable" on launch:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>       <!-- REQUIRED — links the binary -->
    <key>CFBundlePackageType</key>
    <string>APPL</string>                     <!-- REQUIRED — identifies as an app -->
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MyApp</string>
    <key>CFBundleDisplayName</key>
    <string>My App</string>
    <key>CFBundleIdentifier</key>
    <string>com.couchbase.MyApp</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
```

### project.pbxproj generation rules

Model the `project.pbxproj` on the public Couchbase Retail Demo `/iOS` project (see `reference/canonical-references.md`) — adapt UUIDs and file references for the new app. Key settings:
- `IPHONEOS_DEPLOYMENT_TARGET = 16.0`
- `SWIFT_VERSION = 5.0`
- `PRODUCT_BUNDLE_IDENTIFIER = "com.couchbase.<AppName>"`
- `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = <AppName>/Info.plist`
- Include `XCRemoteSwiftPackageReference` for Couchbase Lite **matched to the user's Xcode** (see `installation-and-plist.md`): Xcode 26.2+ → `https://github.com/couchbase/couchbase-lite-swift-ee` (4.x, `upToNextMajor`); Xcode 16.x → `https://github.com/couchbase/couchbase-lite-ios-ee` (newest 3.x — **3.3.0**, `upToNextMinorVersion` `3.3.0`; 3.2.4 fallback). Do **not** pin `from 4.0.3` for an Xcode-16 user — `upToNextMajor` resolves to 4.1 and fails to load. Confirm the current version at https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html
- Include `XCSwiftPackageProductDependency` for `CouchbaseLiteSwift`
- Include `PBXBuildFile` for `CouchbaseLiteSwift in Frameworks`
- Add `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES` to **both Debug and Release** target build configurations
- Add `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")` to **both Debug and Release** — **this is the critical missing piece**; without it the app crashes with `Library not loaded` on standalone launch (home screen tap, second simulator)
- Add the product dependency to `packageProductDependencies` in the native target
- Add an **empty** `PBXCopyFilesBuildPhase` for Embed Frameworks (`files = ()`) — Xcode uses this as a placeholder and manages SPM XCFramework embedding automatically. Do NOT add manual `productRef` entries to the files list.
- **Always resolve packages before the first build**: File → Packages → Resolve Package Versions

Reference implementation: https://github.com/couchbase-examples/couchbase-lite-retail-demo/tree/main/iOS

```
/* PBXBuildFile for embed: */
BADC000BFEED000000000000 = {isa = PBXBuildFile; productRef = <spm-product-uuid>; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };

/* PBXCopyFilesBuildPhase: */
BADC0034FEED000000000000 /* Embed Frameworks */ = {
    isa = PBXCopyFilesBuildPhase;
    buildActionMask = 2147483647;
    dstPath = "";
    dstSubfolderSpec = 10;   /* 10 = Frameworks folder inside .app */
    files = (BADC000BFEED000000000000 /* CouchbaseLiteSwift in Embed Frameworks */,);
    name = "Embed Frameworks";
    runOnlyForDeploymentPostprocessing = 0;
};
```
Add this phase to the target's `buildPhases` list (after Resources). If the packages aren't resolved yet, the build will fail with "No such file" — resolve packages first (File → Packages → Resolve Package Versions), then rebuild.

### After generating everything, tell the user exactly this:

> **First build steps — do these in order:**
>
> 1. Open `<AppName>.xcodeproj` in Xcode
> 2. **File → Packages → Resolve Package Versions** — downloads CouchbaseLiteSwift (~1 min). Do this manually even if Xcode seems to do it automatically; without it the app crashes with `Library not loaded: CouchbaseLiteSwift.framework`
> 3. Select a **Simulator** as the run destination (e.g. iPhone 16). *(No signing needed for the simulator. A Development Team — Xcode → target → Signing & Capabilities → Team — is only required to run on a physical device.)*
> 4. **Cmd+Shift+K** (Clean Build Folder), then **Cmd+R** to **build and run** on the simulator (`Cmd+B` builds without running)
>
> **While packages resolve**, run `setup-capella.sh` to provision your backend (20–45 min).

> **If you get `Library not loaded: CouchbaseLiteSwift.framework`:**
> → File → Packages → Resolve Package Versions, then Cmd+Shift+K, then Cmd+R

---

