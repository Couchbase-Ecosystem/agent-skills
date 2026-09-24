## Android Best Practices (apply to all generated apps)

> Reference the official docs when generating Android code:
> - App architecture / UI layer: https://developer.android.com/topic/architecture
> - Compose state: https://developer.android.com/develop/ui/compose/state
> - ViewModel + StateFlow: https://developer.android.com/topic/libraries/architecture/viewmodel
> - Coroutines & Flow on Android: https://developer.android.com/kotlin/flow
> - Android Keystore: https://developer.android.com/privacy-and-security/keystore
> - App permissions: https://developer.android.com/guide/topics/permissions/overview

### State and data flow

Use a unidirectional flow: `DatabaseManager`/`ReplicationManager` (singletons) expose **`StateFlow`**; a `ViewModel` maps them to UI state; Compose collects with `collectAsStateWithLifecycle()`.

```kotlin
class MovementsViewModel(private val db: DatabaseManager) : ViewModel() {
    val movements: StateFlow<List<Movement>> = db.movementsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
}
```

```kotlin
@Composable
fun MovementsListScreen(vm: MovementsViewModel) {
    val items by vm.movements.collectAsStateWithLifecycle()
    // render items
}
```

- Keep `DatabaseManager`, `ReplicationManager`, and `AuthState` as **process singletons** (a plain `object`, or one instance created in the `Application` and passed down). They outlive individual screens.
- Update `StateFlow` on the main dispatcher; do CBL I/O on `Dispatchers.IO` (`flowOn(Dispatchers.IO)`).

### Credential storage — Android Keystore, never plaintext

Never store the password in plain `SharedPreferences`, `DataStore`, or `UserDefaults`-style storage. **`EncryptedSharedPreferences` (androidx.security-crypto) is deprecated** (since 1.1.0-alpha07, 2025) with known crash/StrictMode issues — do not use it. Instead use the drop-in **`assets/CredentialStore.kt`**, which wraps an AES-GCM key in the **Android Keystore** and stores only ciphertext — no third-party dependency:

```kotlin
CredentialStore(context).savePassword(username, password)   // on login
val pw = CredentialStore(context).loadPassword(username)     // for reconnect after relaunch
CredentialStore(context).clear(username)                     // on sign-out
```

The Keystore key is hardware-backed where available and never leaves the device.

### Async operations — coroutines & Flow

Prefer coroutines over callbacks. Collect live-query and replicator Flows in `viewModelScope`; never block the main thread on CBL calls.

```kotlin
viewModelScope.launch {
    try { authState.login(username, password) }
    catch (e: CouchbaseLiteException) { _error.value = e.message }
}
```

### Listener/token lifecycle

Every `ListenerToken` (query, collection, replicator) must be removed when its owner is destroyed, or it leaks the query/replicator:

```kotlin
override fun onCleared() {
    queryToken?.remove()
    replicatorToken?.remove()
    super.onCleared()
}
```

If you use `queryChangeFlow()` instead of a raw listener, collecting it in `viewModelScope` handles teardown automatically — prefer the Flow API.

### Manifest — permissions & Application class

```xml
<uses-permission android:name="android.permission.INTERNET" />

<application
    android:name=".WarehouseApplication"
    android:allowBackup="false"      <!-- don't back up the local DB / credentials -->
    ... >
```

- `INTERNET` is required for replication.
- WSS (port 4984) is TLS, so **no `usesCleartextTraffic` exemption is needed**. Only a plain `ws://` endpoint would require it — avoid that in production.
- `android:allowBackup="false"` keeps the local database and Keystore-wrapped credentials off cloud backup.

### R8 / ProGuard (release builds)

CBL ships **consumer ProGuard rules**, so a normal release build needs no manual keeps. If you enable aggressive shrinking and hit a `ClassNotFound`/reflection issue, add:

```proguard
-keep class com.couchbase.lite.** { *; }
-keep class com.couchbase.lite.internal.** { *; }
```

Keep `isMinifyEnabled = false` for the demo/dev build to avoid the whole question.

### Mirror the server's access & lock rules on the client (server stays authoritative)

The Access Control Function is the real security boundary — but re-checking its rules on the client gives instant feedback and avoids write-then-reject round-trips. Mirror, don't replace:

```kotlin
// 1. Model — express the rule as data
enum class MovementStatus { OPEN, IN_PROGRESS, DONE, CLOSED;
    val isLocked get() = this == CLOSED         // closed = immutable for non-admins
}
// 2. Data layer — guard before saving (fast local feedback)
fun update(m: Movement) {
    check(!m.status.isLocked || authState.isAdmin) { "Closed movements are admin-only" }
    // ...save...
}
// 3. UI — make locked state visible and non-editable
TextField(value = title, onValueChange = { title = it }, enabled = !isReadOnly)
```

The sync function still enforces the same rule server-side (`if (oldDoc.status === "closed") requireRole("admin")`), so a client that skips the guard cannot bypass it.

### Role-gated UI

Show admin-only controls (create, reassign, delete, set `closed`) only to admins; everyone else gets read/update-own. Gate on a single `isAdmin` flag:

```kotlin
if (authState.isAdmin) {
    IconButton(onClick = onCreate) { Icon(Icons.Default.Add, "New movement") }
}
```

This is UX only — the server enforces `requireRole("admin")`. For **how `isAdmin` is derived**, see `appconfig-kotlin.md`.

---

## Android Requirements

- **Android Studio** (JDK 17 bundled) with **AGP 8.x / Gradle 8.x / Kotlin 2.0+**
- **minSdk 24** by default (CBL 4.x `-ktx` AAR floor — the merger rejects anything lower; every AAR from 3.3.3 up, including 3.4.x, enforces the same floor). **Falls back to minSdk 22 via CBL 3.2.4** for apps that must reach Android 5.1/6.0 devices — a real option with a different (older) Replicator wiring, see `installation-and-config.md` and `cbl-kotlin-apis.md`. compileSdk/targetSdk **35**
- **At least two emulators** installed (the offline-sync test runs the app on two side by side) — Device Manager → add a second AVD
- **Couchbase Lite Android — Enterprise Edition** `couchbase-lite-android-ee-ktx:4.1.0` (custom Couchbase Maven repo) by default — no older-toolchain fallback exists (3.4.0/3.3.3 need the same AGP 8 / JDK 17 / minSdk 24); the real fallback is **3.2.4** (minSdk 22, older Replicator API) for apps that need it — see `installation-and-config.md`
- **Jetpack Compose** + Material 3 for UI

No code signing is needed to run on an emulator (a debug keystore is auto-generated). A release build for the Play Store needs a signing config, which is outside this default flow.

---
