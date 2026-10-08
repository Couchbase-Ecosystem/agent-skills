# App configuration key — `AppServicesEndpointURL` (Android)

The Android client needs exactly **one** app-specific configuration value: the App Services **WebSocket URL** the replicator connects to. It flows: `local.properties` → `BuildConfig` field → `AppConfig.appServicesEndpointURL`.

This is the Android counterpart of the iOS skill's `Info.plist` `AppServicesEndpointURL` key. `setup-capella.sh` fills it in automatically after it provisions the App Endpoint.

## The contract (three touch points — keep them consistent)

1. **`local.properties`** (project root, developer-local, git-ignored) — the value lives here under the key **`cbl.endpointUrl`**:

   ```properties
   cbl.endpointUrl=wss://PLACEHOLDER.apps.cloud.couchbase.com:4984/PLACEHOLDER
   ```

   Generate the project with the PLACEHOLDER line present so the build compiles before provisioning; the script overwrites it.

2. **`app/build.gradle.kts`** — expose it as a `BuildConfig` field (requires `buildFeatures { buildConfig = true }`):

   ```kotlin
   buildConfigField("String", "APP_SERVICES_ENDPOINT_URL", "\"${cblProp("cbl.endpointUrl")}\"")
   ```

   (`cblProp` reads `local.properties`, falling back to a Gradle property / env var — see `reference/installation-and-config.md`.)

3. **`AppConfig.kt`** — read and validate (see `reference/appconfig-kotlin.md`):

   ```kotlin
   val appServicesEndpointURL: String
       get() = BuildConfig.APP_SERVICES_ENDPOINT_URL.also {
           require(it.isNotBlank() && !it.contains("PLACEHOLDER")) {
               "APP_SERVICES_ENDPOINT_URL not set. Run setup-capella.sh, then re-sync Gradle."
           }
       }
   ```

## How `setup-capella.sh` writes it

The provisioning script detects an Android project — a `local.properties` beside a `settings.gradle(.kts)`, with **no** iOS `Info.plist` — and writes the resolved `wss://…:4984/<endpoint>` URL to the `cbl.endpointUrl` key (adding the line if absent, replacing it if present). It does the same job the iOS branch does with `plutil` on `Info.plist`.

> **After the script runs, the user must re-sync Gradle** (Android Studio: File → Sync Project with Gradle Files, or `./gradlew --refresh-dependencies`) so `BuildConfig` regenerates with the real URL. Kotlin source reads the *compiled* `BuildConfig`, so a stale sync means the app still sees the PLACEHOLDER.

## Why not hardcode it?

- The URL is environment-specific (each App Endpoint has its own host) — hardcoding it in source means editing Kotlin for every deployment.
- `local.properties` is developer-local by convention (in the default `.gitignore`), so a real endpoint URL never gets committed.
- `BuildConfig` is the Android-standard way to surface build-time config to code — no runtime file I/O, no extra config file to ship.
