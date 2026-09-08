### Generated `AppConfig.kt` — required constants

```kotlin
object AppConfig {
    const val databaseName = "WarehouseDB"

    // Named scope — NEVER "_default" for app data
    const val scopeName = "warehouse"          // matches COLLECTIONS env var scope

    // One constant per collection
    const val movementsCollection = "movements"
    const val stockCollection = "stock"

    // Channels
    const val adminChannel = "admin"           // channel for App Users with the admin App Role

    // The manager App User holds the admin App Role and sees all documents.
    // Must match MANAGER_USER in setup-capella.sh (default: "manager").
    // Distinct from the App Services Admin Credential (infrastructure only — not a mobile user).
    const val managerUsername = "manager"

    // WebSocket endpoint — injected at build time from local.properties (cbl.endpointUrl)
    val appServicesEndpointURL: String
        get() = BuildConfig.APP_SERVICES_ENDPOINT_URL.also {
            require(it.isNotBlank() && !it.contains("PLACEHOLDER")) {
                "APP_SERVICES_ENDPOINT_URL not set. Run setup-capella.sh, then re-sync Gradle."
            }
        }
}
```

**`isAdmin` in `AuthState` must use `AppConfig.managerUsername`**, not a hardcoded `"admin"`:

```kotlin
// WRONG — "admin" is the App Services Admin Credential, not an App User:
val isAdmin = username == "admin"

// CORRECT — "manager" is the App User with the admin App Role:
val isAdmin = username == AppConfig.managerUsername
```

The `scopeName` must exactly match the scope used in:
- the `COLLECTIONS` env var for `setup-capella.sh` (e.g. `warehouse/movements warehouse/stock`)
- CBL queries: `SELECT META().id, * FROM warehouse.movements WHERE …`
- CBL collection open: `db.createCollection("movements", "warehouse")`
- the Access Control Function header comment and filenames (`movements-sync-function.js`)

Domain examples with correct scope naming:

| Domain | Scope | Collections | COLLECTIONS env var | Endpoint name |
|---|---|---|---|---|
| Warehouse | `warehouse` | `movements`, `stock` | `warehouse/movements warehouse/stock` | `warehouse` |
| Field inspection | `fieldops` | `inspections`, `assets` | `fieldops/inspections fieldops/assets` | `fieldtracker` |
| Retail POS | `retail` | `transactions`, `inventory` | `retail/transactions retail/inventory` | `retail-app` |
| Todo / task app | `todo` | `todos` | `todo/todos` | `todosync` |

The chosen collection names are the contract shared by the client (`AppConfig.kt`), the Access Control Function filenames, and the `COLLECTIONS` provisioning env var — keep all three identical.
