## Couchbase Lite Swift — Installation

> ⚠️ **The CouchbaseLiteSwift SPM version MUST match the user's Xcode toolchain**, or the build fails with `Failed to build module 'CouchbaseLiteSwift'; this SDK is not supported by the compiler`. Pick the SDK line from the Xcode version — do NOT just take "latest".

### Pick the CBL line from the Xcode version (check the version FIRST)

| Xcode | Couchbase Lite line | SPM URL | Version requirement |
|---|---|---|---|
| **26.2+** (Swift 6.2.3+) | **4.x — latest, recommended** | `https://github.com/couchbase/couchbase-lite-swift-ee.git` | `upToNextMajor` from the current 4.x (e.g. 4.1.0) |
| **16.3 – 16.4** (Swift 6.1 – 6.1.2) | **4.x — latest** (4.1.x loads on Swift 6.1+) | `https://github.com/couchbase/couchbase-lite-swift-ee.git` | `upToNextMajor` from the current 4.x (e.g. 4.1.0) |
| **16.0 – 16.2** (Swift 6.0.x, e.g. 16.2 = Swift 6.0.3) | **4.0.x** (same 4.x API; 4.1.x and 3.4.x need Swift 6.1+ — don't drop to 3.x) | `https://github.com/couchbase/couchbase-lite-swift-ee.git` | `upToNextMinor` from `4.0.4` |
| Older than 16.0 (Swift 5.x) | Not supported by this skill — ask the user to update Xcode to 16.0+ | — | — |

- **Use the *newest compatible* CBL, not the oldest.** Xcode 16.3+ (Swift 6.1+) loads the latest 4.x — pin **4.1.x**. Xcode 16.0–16.2 (Swift 6.0.x) cannot load 4.1.x (`this SDK is not supported by the compiler`) — pin **4.0.x** instead. There is no reason to drop to the 3.x line.
- Product name is **`CouchbaseLiteSwift`**; distributed as an **XCFramework**. This skill uses **Enterprise Edition** by default -- SPM repo `couchbase-lite-swift-ee.git` (all versions, 3.x and 4.x). **Licensing:** EE is free for development and testing; production requires a Couchbase Enterprise license. (Community Edition -- `couchbase-lite-swift.git` (4.x) / `couchbase-lite-ios.git` (3.x), license-free, cloud-edge only -- is the alternative.)
- **Do NOT pin `from 4.0.x` with `upToNextMajor` on Xcode 16.0–16.2** — it slides up to 4.1.x (built with Swift 6.2.3, needs Swift 6.1+) and fails to load. That's the #1 cause of this error. Use `upToNextMinor` from `4.0.4` so it stays on 4.0.x.
- The 4.0.x API is identical to 4.1.x for everything this skill generates (`createCollection`, SQL++ `createQuery`, the `ReplicatorConfiguration(collections:target:)` constructor, `ValueIndexConfiguration`, `LogSinks`). NOTE: use the **collections-initializer** replicator form (`ReplicatorConfiguration(collections:target:)` + `CollectionConfiguration(collection:)`) — the old `ReplicatorConfiguration(target:)` + `addCollection(...)` form was removed in 4.0.
- The EE SPM repo is `couchbase-lite-swift-ee.git` for every version. (There is no `couchbase-lite-ios-ee.git` and no `couchbase-lite-ios-app.git` -- those repos don't exist.)
- **4.0.x on Xcode 16.0–16.2 is a verified path** (4.0.4 builds on Xcode 16.0 and 16.2). 4.1.x and 3.4.x are built with Swift 6.2.3 and require Swift 6.1+ (Xcode 16.3+); 4.0.x has no such requirement.
- **Do not override this table by inspecting the XCFramework's own files** (e.g. a `swift-compiler-version:` line inside a `.swiftinterface`, which for a 4.0.x build commonly reads something newer, like 6.1.2). That string records which compiler *produced* the module, not the minimum needed to *consume* it -- Swift's module stability lets a module built with a newer compiler load on a compatible older toolchain. Reading it as a hard minimum and second-guessing the table produces a false blocker: **4.0.4 building and running on Xcode 16.2 is empirically confirmed** (user-tested, 2026-09-23), matching what the table above already says. If the two ever seem to disagree, trust the table, not the framework metadata -- or ask the user to just try the build before treating it as broken.
- Version numbers move — confirm the current 4.x at https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html and the latest 4.0.x at https://docs.couchbase.com/couchbase-lite/4.0/swift/gs-install.html.

Add via **File → Add Package Dependencies** with the URL + requirement from the table above; select product `CouchbaseLiteSwift`.

**After adding OR changing the package version:**
1. **File → Packages → Reset Package Caches** (essential after switching the URL/version — stale resolution otherwise sticks)
2. File → Packages → Resolve Package Versions (wait for full completion)
3. Cmd+Shift+K (Clean Build Folder)
4. Cmd+R

> **Cascade error, not a real bug:** a `DocumentID` / `wrappedValue` compile error in the model files is a *side effect* of the SDK failing to load. It disappears once the SDK builds against the right toolchain — don't "fix" the model code.

**Required build settings** (verified against https://github.com/couchbase-examples/couchbase-lite-retail-demo):
- `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")` — without this the app crashes on standalone launch
- An **empty** `PBXCopyFilesBuildPhase` for Embed Frameworks — Xcode manages SPM XCFramework embedding automatically via this placeholder; do not add manual entries to its `files` list

---

## App Configuration Pattern — Info.plist (Apple-recommended)

**Always use Info.plist for app configuration values like the WSS endpoint URL.** This is Apple's recommended pattern — Info.plist is always present in the app bundle, no separate file to create or find, and readable at runtime via `Bundle.main`.

**Do NOT use a separate Config.plist** — it requires users to manually create it, it's easy to miss, and it's not the Apple standard.

**In Info.plist** — add a placeholder key that the script overwrites:
```xml
<key>AppServicesEndpointURL</key>
<string>wss://PLACEHOLDER.apps.cloud.couchbase.com:4984/PLACEHOLDER</string>
```

**In AppConfig.swift** — read from `Bundle.main`:
```swift
static var appServicesEndpointURL: URL {
    guard
        let urlString = Bundle.main.object(forInfoDictionaryKey: "AppServicesEndpointURL") as? String,
        !urlString.hasPrefix("wss://PLACEHOLDER"),
        let url = URL(string: urlString)
    else {
        fatalError("AppServicesEndpointURL not set in Info.plist. Run setup-capella.sh.")
    }
    return url
}
```

**Script auto-updates Info.plist** using `plutil` (Apple's built-in plist tool):
```bash
plutil -replace AppServicesEndpointURL -string "$wss_url" "$CONFIG_PLIST_PATH"
```

No configuration needed — the script auto-detects `Info.plist` using `find . -name "Info.plist"` (excluding DerivedData, Pods, and .xcodeproj paths).

---

