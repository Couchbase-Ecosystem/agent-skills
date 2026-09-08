## Couchbase Lite Swift — Installation

> ⚠️ **The CouchbaseLiteSwift SPM version MUST match the user's Xcode toolchain**, or the build fails with `Failed to build module 'CouchbaseLiteSwift'; this SDK is not supported by the compiler`. Pick the SDK line from the Xcode version — do NOT just take "latest".

### Pick the CBL line from the Xcode version (check the version FIRST)

| Xcode | Couchbase Lite line | SPM URL | Version requirement |
|---|---|---|---|
| **26.2+** (Swift 6.2.3+) | **4.x — latest, recommended** | `https://github.com/couchbase/couchbase-lite-swift-ee.git` | `upToNextMajor` from the current 4.x (e.g. 4.1.0) |
| **16.x** (e.g. 16.2 = Swift 6.0.3) | **Newest 3.x — 3.3.0** (the 3.x line is the Xcode-16-compatible line; don't drop to 3.2 unless needed) | `https://github.com/couchbase/couchbase-lite-ios-ee.git` | `upToNextMinor` from `3.3.0` |

- **Use the *newest compatible* CBL, not the oldest.** On Xcode 16.x the 3.x line applies — pin **3.3.0** (latest 3.x). Only if 3.3.0 still throws `this SDK is not supported by the compiler` on the user's Xcode, step down to **3.2.4**. The 4.x line is separate (Xcode 26.2+).
- Product name is **`CouchbaseLiteSwift`**; distributed as an **XCFramework**. This skill uses **Enterprise Edition** by default -- SPM repos `couchbase-lite-swift-ee.git` (4.x) / `couchbase-lite-ios-ee.git` (3.x). **Licensing:** EE is free for development and testing; production requires a Couchbase Enterprise license. (Community Edition -- `couchbase-lite-swift.git` / `couchbase-lite-ios.git`, license-free, cloud-edge only -- is the alternative.)
- **Do NOT pin `from 4.0.3` with `upToNextMajor` on Xcode < 26.2** — it slides up to 4.1.0 (built with Swift 6.2.3) and fails to load on Xcode 16.x. That's the #1 cause of this error. (And `upToNextMajor from 3.3.0` would also slide to 4.x — use `upToNextMinor` so it stays on 3.3.x.)
- The 3.3.x API is compatible with this skill's generated code (`createCollection`, SQL++ `createQuery`, the `ReplicatorConfiguration(collections:target:)` constructor, `ValueIndexConfiguration`). NOTE: use the **collections-initializer** replicator form (`ReplicatorConfiguration(collections:target:)` + `CollectionConfiguration(collection:)`), which works on both 3.3.x and 4.x — the old `ReplicatorConfiguration(target:)` + `addCollection(...)` form was removed in 4.0.
- 3.x EE SPM repo is `couchbase-lite-ios-ee.git`; 4.x EE uses `couchbase-lite-swift-ee.git`. (CE equivalents drop the `-ee`. NOT `couchbase-lite-ios-app.git` -- that repo doesn't exist.)
- **4.0.x on Xcode 16.x is NOT a verified path.** 4.0.0 shipped Oct 2025 (around Xcode 26.0/Swift 6.2), and the docs don't publish its build toolchain — it may need Xcode 26.0+. Don't offer it as an Xcode-16 option; use **3.3.0** for Xcode 16.x, and **4.1 on Xcode 26.2+** for the latest.
- Version numbers move — confirm the current 3.x and 4.x at https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html (4.x) and https://docs.couchbase.com/couchbase-lite/3.3/swift/gs-install.html (3.x).

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

