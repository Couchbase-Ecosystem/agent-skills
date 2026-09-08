### 2. Couchbase Retail Demo — for Xcode project structure and build settings

```
https://github.com/couchbase-examples/couchbase-lite-retail-demo
```

This is the **official Couchbase multi-language reference app** (iOS, Android, Flutter, React Native, .NET, and more). The `/iOS` folder is the verified reference for:
- Correct `project.pbxproj` structure for CouchbaseLiteSwift via SPM
- Required build settings (`LD_RUNPATH_SEARCH_PATHS`, `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`)
- Correct empty `Embed Frameworks` build phase for SPM XCFrameworks
- SPM package URL, version, and product dependency wiring

**When any build setting question arises, fetch and check this repo before guessing.** Do not hardcode build settings from memory — the reference app is the ground truth.

For other platforms (Android, Flutter, etc.), consult the corresponding subdirectory in the same repo.

> **This is a shared, multi-platform reference (public repo).** README: https://github.com/couchbase-examples/couchbase-lite-retail-demo/blob/main/README.md — iOS, Android, Flutter, React Native, .NET, and more. It is *per-client* ground truth: this iOS skill uses the `/iOS` subdirectory; a future `couchbase-lite-android-app` skill uses `/android`, etc. Each client skill keeps its own platform-specific build settings; only the repo pointer is shared.
>
> **This public repo is also the reference implementation** (worked example) for structure, replication, live queries, P2P, and multi-platform — see `couchbase-mobile-cloud-edge-sync-app/reference/reference-implementation.md`. Its one gap, a simple store-isolation access model, is filled in-skill by `couchbase-mobile-access-control-function/reference/example-comprehensive-access-model.md`. (That comprehensive model was distilled from an internal FieldTaskTracker app that is **not** bundled or published — don't link to it.)

### 3. Couchbase Lite Swift docs — for CBL API usage

```
https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html   ← installation + current version
https://docs.couchbase.com/couchbase-lite/current/swift/                   ← full Swift SDK docs
```

Always check the current CBL version before setting the SPM requirement — and **match it to the user's Xcode** (4.x needs Xcode 26.2+; use 3.2.x on Xcode 16.x). See `installation-and-plist.md`. The version in training data may be stale.

**Verify every CBL API against these docs + the reference app before using it, and never emit a deprecated/removed 3.x API** (e.g. the removed `Database.log.console` logging accessor). Training data lags the SDK — when in doubt, fetch the docs. See Rule 0 in `xcode-project-generation.md`.

### 4. Apple Developer Documentation — for all iOS/Swift platform APIs

Always link to and follow Apple's official docs. Key references — **check these before generating any platform code:**

| Topic | Reference |
|---|---|
| SwiftUI data flow | https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app |
| `@MainActor` / concurrency | https://developer.apple.com/documentation/swift/mainactor |
| Keychain Services | https://developer.apple.com/documentation/security/keychain_services |
| Info.plist keys | https://developer.apple.com/documentation/bundleresources/information-property-list |
| Privacy manifest | https://developer.apple.com/documentation/bundleresources/privacy_manifest_files |
| async/await | https://developer.apple.com/documentation/swift/concurrency |
| Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines |
| Toolbar HIG | https://developer.apple.com/design/human-interface-guidelines/toolbars |

**Platform best practices from Apple docs that must be followed in every generated app:**
- Credentials: Keychain Services only — never `UserDefaults`
- Config values (URLs): `Info.plist` + `Bundle.main.object(forInfoDictionaryKey:)` — not a separate plist file
- Concurrency: `@MainActor` on all `ObservableObject` subclasses; `async/await` over callbacks
- Privacy: include `PrivacyInfo.xcprivacy` if using covered APIs (required for App Store from iOS 17+)
- Toolbar: use `.topBarLeading` / `.topBarTrailing` — `navigationBarLeading/Trailing` are deprecated

---

