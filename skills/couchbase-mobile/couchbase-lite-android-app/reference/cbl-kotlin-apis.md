## CBL Android/Kotlin SDK — Key APIs

The Android SDK exposes the same Collection/Scope/Query/Replicator model as the Swift SDK; the idioms differ (Kotlin Flow for live queries, `CharArray` passwords, a mandatory `init` step). Snippets below target the **4.x line** (Enterprise Edition `couchbase-lite-android-ee-ktx`); the same surface exists on 3.4.x.

### Initialize the SDK (mandatory on Android — no Swift equivalent)

`CouchbaseLite.init(context)` **must run once before any other CBL call**, or the first database open throws. Do it in `Application.onCreate()`:

```kotlin
class WarehouseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CouchbaseLite.init(this)
        // Verbose console logging in debug — filter Logcat by "CouchbaseLite" to watch sync/auth/replication.
        // Uses the LogSinks API, present from 3.3.x through 4.x (the old Database.log.console was removed in 4.0).
        // IMPORTANT — package: LogSinks + ConsoleLogSink live in `com.couchbase.lite.logging`
        //   (LogLevel/LogDomain are in `com.couchbase.lite`). Importing LogSinks from the wrong package is the
        //   usual cause of "unresolved reference 'LogSinks'". Required imports:
        //     import com.couchbase.lite.LogLevel
        //     import com.couchbase.lite.logging.ConsoleLogSink
        //     import com.couchbase.lite.logging.LogSinks
        if (BuildConfig.DEBUG) {
            LogSinks.get().setConsole(ConsoleLogSink(LogLevel.VERBOSE))   // all domains; scope with extra LogDomain args
        }
    }
}
```

> ⚠️ **Logging API — use `LogSinks` (it is cross-version, 3.3.x → 4.x).** The old `Database.log` / `Database.log.console` accessor was **removed in 4.0** (→ "unresolved reference 'log'") — never use it. `LogSinks`/`ConsoleLogSink` have existed since **3.3.x** (verified in the 3.3.0, 3.4.0 and 4.1.0 API refs), so they compile across the whole supported range. **Package matters:** `LogSinks` and `ConsoleLogSink` are in `com.couchbase.lite.logging`; `LogLevel`/`LogDomain` are in `com.couchbase.lite`. Importing `com.couchbase.lite.LogSinks` (wrong package) is what produces "unresolved reference 'LogSinks'". Set it with `LogSinks.get().setConsole(ConsoleLogSink(LogLevel.VERBOSE))`. Ref: https://docs.couchbase.com/mobile/4.1.0/couchbase-lite-android/com/couchbase/lite/logging/package-summary.html

Register it in the manifest: `<application android:name=".WarehouseApplication" …>`.

### Open Database & named-scope Collection

```kotlin
val db = Database("WarehouseDB", DatabaseConfiguration())
// Always use a named scope — never the "_default" scope
val movements: Collection = db.createCollection("movements", "warehouse")
    // getCollection(name, scope) returns null if it doesn't exist; createCollection is idempotent
```

### CRUD

```kotlin
// Create
val doc = MutableDocument("movement::${UUID.randomUUID()}").apply {
    setString("type", "movement")
    setString("title", "Pick 40 units SKU-1234")
    setString("status", "open")
}
movements.save(doc)

// Read
val fetched = movements.getDocument(docId)          // Document? (null if absent)
val title = fetched?.getString("title")

// Update (documents are immutable — edit a mutable copy)
val mutable = fetched!!.toMutable()
mutable.setString("status", "done")
movements.save(mutable)

// Delete (tombstone — syncs as a deletion)
movements.delete(fetched)
```

> `CouchbaseLiteException` is a **checked** exception — CRUD, query, and index calls must be inside `try/catch` (or a `@Throws` function). This differs from Swift's `throws`/`do-catch`.

### Indexes (query performance)

Create a **value index** on fields you filter or sort on, once, right after opening the collection — without one, live queries do a full scan and slow down as data grows:

```kotlin
movements.createIndex(
    "movementAssigneeStatus",
    ValueIndexConfiguration("assignee", "status")
)
```

Any field in a `WHERE`, `ORDER BY`, or `MATCH` clause should be indexed (value index for equality/range/sort, `FullTextIndexConfiguration` for `MATCH`). Bind user-supplied values with `Parameters`, never string-interpolate them.

### Live Query — idiomatic Kotlin Flow (from `-ktx`)

The `-ktx` artifact adds `queryChangeFlow()` (in package **`com.couchbase.lite`** — defined in `CommonFlowsKt`, verified in the 3.3.0 and 4.1.0 KTX API refs; the reference app imports it via `com.couchbase.lite.*`). It emits whenever results change. Collect it in a `viewModelScope` so it's lifecycle-bound:

```kotlin
import com.couchbase.lite.queryChangeFlow            // official KTX extension: com.couchbase.lite (CommonFlowsKt).
                                                     // NOT com.couchbase.lite.kotlin — that's the 3rd-party MOLO17 lib and gives "unresolved reference 'queryChangeFlow'".

val query = db.createQuery(
    "SELECT META().id AS id, * FROM warehouse.movements " +
    "WHERE type = 'movement' ORDER BY createdAt DESC"
)

query.queryChangeFlow()
    .map { change ->
        change.error?.let { throw it }
        change.results?.allResults().orEmpty().mapNotNull { result ->
            val id = result.getString("id") ?: return@mapNotNull null
            val dict = result.getDictionary("movements")?.toMap() ?: return@mapNotNull null
            Movement.from(id, dict)
        }
    }
    .flowOn(Dispatchers.IO)
    .collect { items -> _movements.value = items }   // update StateFlow on the main dispatcher
```

> The projected doc is nested under the **collection name** (`result.getDictionary("movements")`) because the query is `SELECT * FROM warehouse.movements`. Alias with `AS` if you prefer.

### Live Query — change-listener + token (non-Flow alternative)

```kotlin
val token: ListenerToken = query.addChangeListener { change ->
    change.results?.allResults()?.let { /* map + post to StateFlow */ }
}
// later, in onCleared():
token.remove()      // 3.1+ style — replaces the old query.removeChangeListener(token)
```

Always `remove()` the token when the owning ViewModel is cleared, or the query leaks.

### Replicator Setup (cloud-edge → Capella App Services)

```kotlin
val endpoint = URLEndpoint(URI(AppConfig.appServicesEndpointURL))   // wss://…:4984/warehouse
// Pass a Collection<CollectionConfiguration> to the constructor. Each CollectionConfiguration
// WRAPS a Collection via CollectionConfiguration(collection). This is the ONLY form valid across
// 3.3.x–4.x. The old ReplicatorConfiguration(endpoint) + addCollection(...) + no-arg
// CollectionConfiguration() forms compile on 3.x but were REMOVED in 4.1.
val collConfigs = setOf(
    // Pass the Collection OBJECTS you created (e.g. what your DatabaseManager exposes:
    // db.createCollection("movements","warehouse")) — NOT the collection-name strings.
    CollectionConfiguration(movements),
    CollectionConfiguration(stock),
    // .apply { channels = listOf(...) }  // optional per-collection channels/pull filter
)
val config = ReplicatorConfiguration(collConfigs, endpoint).apply {
    type = ReplicatorType.PUSH_AND_PULL
    isContinuous = true
    authenticator = BasicAuthenticator(username, password.toCharArray())  // CharArray, not String
}
val replicator = Replicator(config)
val token = replicator.addChangeListener { change ->
    val level = change.status.activityLevel          // STOPPED, OFFLINE, CONNECTING, IDLE, BUSY
    val error = change.status.error                  // CouchbaseLiteException? (401 = bad creds, etc.)
}
replicator.start()
```

> Password is a `CharArray` (Swift takes a `String`). Wrap **every** collection you sync in its own `CollectionConfiguration(collection)` and put it in the `collConfigs` set. The `ReplicatorConfiguration(Collection<CollectionConfiguration>, Endpoint)` constructor + `CollectionConfiguration(collection)` exist in **both 3.3.x and 4.1.x** (verified in both API refs); the 3.x `ReplicatorConfiguration(endpoint)` + `addCollection` form was removed in 4.1. Per-collection channels/filters: `CollectionConfiguration(collection).apply { channels = listOf("…") }`.

### Full-Text Search

```kotlin
movements.createIndex("movementFTS", FullTextIndexConfiguration("title"))

val q = db.createQuery(
    "SELECT META().id FROM warehouse.movements WHERE MATCH(movementFTS, \$term)"
).apply { parameters = Parameters().apply { setString("term", "fire safety") } }
```

### Blobs (file attachments)

```kotlin
val blob = Blob("image/jpeg", imageBytes)      // or Blob("image/jpeg", inputStream)
doc.setBlob("photo", blob)
movements.save(doc)

val out = movements.getDocument(docId)?.getBlob("photo")?.content   // ByteArray?
```

> Blobs are always attached to a document — they cannot be standalone.

---

## Differences from the Swift SDK (call these out when porting)

| Concern | Swift (iOS) | Kotlin (Android) |
|---|---|---|
| One-time init | none | **`CouchbaseLite.init(context)`** in `Application.onCreate()` |
| Live query | closure / Combine | **`queryChangeFlow()`** (Kotlin Flow) or `addChangeListener` + `ListenerToken` |
| Auth password | `String` | **`CharArray`** (`password.toCharArray()`) |
| Errors | `throws` / `do-catch` | **checked `CouchbaseLiteException`** (try/catch or `@Throws`) |
| Config value store | `Info.plist` + `Bundle.main` | **`BuildConfig`** field from `local.properties` |
| Credential store | Keychain | **Android Keystore** (`assets/CredentialStore.kt`) |
| Listener removal | `token = nil` | `token.remove()` |

---
