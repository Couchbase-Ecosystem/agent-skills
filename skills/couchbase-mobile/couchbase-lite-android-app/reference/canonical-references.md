## Canonical references — check these before generating code

### 1. Couchbase Retail Demo — for Gradle project structure and dependency wiring

```
https://github.com/couchbase-examples/couchbase-lite-retail-demo/tree/main/Android
```

The **official Couchbase multi-language reference app** (iOS, Android, Flutter, React Native, .NET, and more). The `/Android` folder ("GroceryApp") is the verified reference for:
- `settings.gradle.kts` repository setup and `app/build.gradle.kts` structure
- the Couchbase Lite dependency line and Compose/Material 3 wiring
- `buildConfig` / `buildConfigField` usage for injecting config values
- `namespace`, `compileSdk`/`minSdk`/`targetSdk`, Java/Kotlin compatibility

**When any build setting question arises, fetch and check this repo before guessing.** Do not hardcode build settings from memory.

> **Edition:** the demo uses the **Enterprise Edition** coordinate (`couchbase-lite-android-ee-ktx`) and the custom Couchbase Maven repo -- **the same as this skill's default (EE)**, so mirror it directly. (Community Edition -- `couchbase-lite-android-ktx` from Maven Central, license-free, cloud-edge only -- is the alternative; see `installation-and-config.md`.)

This public repo is the same shared, multi-platform reference the iOS skill uses (its `/iOS` folder); each client skill takes its own platform subdirectory. Its one gap — a simple store-isolation access model — is filled in-skill by `couchbase-mobile-access-control-function`.

### 2. Couchbase Lite Android docs — for CBL API usage and the current version

```
https://docs.couchbase.com/couchbase-lite/current/android/gs-install.html   ← install + current version
https://docs.couchbase.com/couchbase-lite/current/android/gs-prereqs.html    ← toolchain prerequisites
https://docs.couchbase.com/couchbase-lite/current/android/                    ← full Android SDK docs
```

Always confirm the current CBL Android version before pinning the dependency (the version in training data may be stale). Default to the latest **4.x** on a modern Android Studio; drop to the newest **3.x** only for older AGP/JDK toolchains — see `installation-and-config.md`.

**Verify every CBL API against these docs + the reference app before using it, and never emit a deprecated/removed 3.x API** (e.g. the removed `Database.log.console` logging accessor). Training data lags the SDK — when in doubt, fetch the docs. See Rule 0 in `gradle-project-generation.md`.

### 3. Android Developer Documentation — for platform APIs

Check these before generating platform code:

| Topic | Reference |
|---|---|
| App architecture (UI layer) | https://developer.android.com/topic/architecture |
| Compose state | https://developer.android.com/develop/ui/compose/state |
| ViewModel | https://developer.android.com/topic/libraries/architecture/viewmodel |
| Coroutines & Flow | https://developer.android.com/kotlin/flow |
| Android Keystore | https://developer.android.com/privacy-and-security/keystore |
| Permissions | https://developer.android.com/guide/topics/permissions/overview |
| Material 3 (Compose) | https://developer.android.com/develop/ui/compose/designsystems/material3 |

**Platform best practices that must be followed in every generated app:**
- Credentials: **Android Keystore** (`assets/CredentialStore.kt`) — never plain `SharedPreferences`/`DataStore`, and not the deprecated `EncryptedSharedPreferences`.
- Config values (URLs): **`BuildConfig`** field from `local.properties` — not hardcoded in source.
- State: **ViewModel + StateFlow**; collect in Compose with `collectAsStateWithLifecycle()`.
- Concurrency: **coroutines/Flow**; CBL I/O off the main thread; remove every `ListenerToken`.
- Manifest: **`INTERNET`** permission; register the `Application` subclass that calls `CouchbaseLite.init`.

---
