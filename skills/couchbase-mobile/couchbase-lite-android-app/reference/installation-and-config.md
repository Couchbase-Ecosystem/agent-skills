## Couchbase Lite Android — Installation

> Confirm the current version before pinning — check https://docs.couchbase.com/couchbase-lite/current/android/gs-install.html . Version numbers move; the numbers below were current as of this writing.

### Edition & coordinates -- use Enterprise Edition (custom Couchbase Maven repo)

This skill uses the **Enterprise Edition (EE)** of Couchbase Lite by default (cloud-edge replication to Capella App Services / Sync Gateway works in EE, and EE also unlocks P2P, database encryption, and vector search). EE resolves from the **custom Couchbase Maven repository** `https://mobile.maven.couchbase.com/maven2/dev/` -- add it in `settings.gradle.kts` (see `gradle-project-generation.md`). Use the **EE Kotlin extensions** artifact, which transitively includes the base library and adds the `queryChangeFlow` Flow APIs. **Licensing:** EE is free for development and testing; production deployment requires a Couchbase Enterprise license/subscription.

```kotlin
// app/build.gradle.kts
dependencies {
    implementation("com.couchbase.lite:couchbase-lite-android-ee-ktx:4.1.0")
}
```

| Edition | Coordinate | Repo | Adds |
|---|---|---|---|
| **Enterprise (use this)** | `com.couchbase.lite:couchbase-lite-android-ee-ktx:4.1.0` | Couchbase Maven repo `mobile.maven.couchbase.com/maven2/dev/` | cloud-edge replication, local DB, query, FTS, + P2P / encryption / vector search |
| Community (license-free alternative) | `com.couchbase.lite:couchbase-lite-android-ktx:4.1.0` | Maven Central | cloud-edge replication, local DB, query, FTS (no P2P / encryption / vector search) |

- **This skill defaults to Enterprise Edition:** add the EE Maven repo `https://mobile.maven.couchbase.com/maven2/dev/` in `settings.gradle.kts` and use the `-ee-ktx` coordinate. **To switch to Community later** (license-free, cloud-edge only -- no P2P/encryption/vector search), drop the custom repo and use `couchbase-lite-android-ktx` from Maven Central instead.
- The product includes native `.so` libraries for all ABIs; no NDK setup or ABI filter is required for a standard build.
- Older toolchains: the newest **3.x** line is `couchbase-lite-android-ee-ktx:3.4.0` (same Collection/Scope API; the 3.4.x line's floor is **minSdk 22**, vs **24** for 4.x). **Default to the latest 4.x (4.1.0)** on any modern Android Studio (JDK 17 / AGP 8) — this mirrors the iOS skill's policy: latest 4.x on a modern toolchain, newest 3.x only as a fallback. Drop to 3.4.0 only when the toolchain can't run AGP 8 / JDK 17.

### Toolchain compatibility band

Modern Android Studio bundles the JDK and a compatible AGP, so — unlike iOS, where the Xcode version forces the SDK line — Android is uniformly modern; **default to the latest 4.x** (currently **4.1.0** — pin the newest available, per the confirm-version note at the top of this file; fall back to the newest 3.x = **3.4.0** only for older toolchains). Requirements:

| Setting | Value |
|---|---|
| `minSdk` | **24** (Android 7.0) for the **4.x** line — the `couchbase-lite-android(-ee)-ktx:4.x` AAR **declares minSdk 24 in its own manifest**, so the project must be >= 24 or the build fails with *"uses-sdk:minSdkVersion 22 cannot be smaller than version 24 declared in library"*. (The docs prereq page still says 22, but the shipped 4.1.0 artifact enforces 24 — the artifact wins.) The **3.4.x** line's floor is **22**. Raise only if your app needs newer APIs. |
| `compileSdk` / `targetSdk` | **35** |
| JDK to run the build | **17** (bundled with Android Studio; required by AGP 8) |
| Source/target compatibility | Java **8** is fine (`VERSION_1_8` / `jvmTarget = "1.8"`) — CBL ships Java-8 bytecode |
| Android Gradle Plugin | **8.x** (e.g. 8.7) |
| Gradle | **8.x** (e.g. 8.9) |
| Kotlin | **2.0+** (Compose apps use the `org.jetbrains.kotlin.plugin.compose` compiler plugin) |

> **Set the Gradle JVM to 17 before the first sync.** New Android Studio (Narwhal / 2025+) defaults the Gradle JVM (**Settings → Build, Execution, Deployment → Build Tools → Gradle → _Default Gradle JVM criteria → Version_**, or **Gradle JVM** on older UIs) to a very recent JDK such as **24 or 25**. The bundled **Gradle 8.9** wrapper only runs on **JDK 17–22** (JDK 25 needs Gradle 9.1+), so a JDK-25 default fails the build with *"Gradle 8.9 requires Java …"* or an unsupported-class-file error. Set it to the embedded **JBR (17)** or any JDK 17–21.

If the user is on an older AGP/JDK that can't move to 8/17, pin `couchbase-lite-android-ee-ktx:3.4.0` (newest 3.x; same minSdk 22, same Collection/Scope API) and set AGP accordingly — but recommend upgrading Android Studio first.

### After adding OR changing the dependency

1. **File → Sync Project with Gradle Files** (or `./gradlew --refresh-dependencies`).
2. Build & run: `./gradlew assembleDebug`, or Run ▶ in Android Studio onto an emulator.

R8/minification is off by default for debug; CBL ships **consumer ProGuard rules**, so release builds need no manual `-keep` for Couchbase. See `android-best-practices.md` for the fallback rule if you enable aggressive shrinking.

---

## App Configuration Pattern — `BuildConfig` from `local.properties`

**Inject the App Services WebSocket URL as a `BuildConfig` field**, sourced from `local.properties` (developer-local, not checked in) with a Gradle-property / env fallback. This is the Android-idiomatic equivalent of iOS reading `Info.plist`, and it's what `setup-capella.sh` writes into.

**In `app/build.gradle.kts`:**

```kotlin
import java.util.Properties

val cblProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun cblProp(name: String): String =
    (cblProps.getProperty(name) ?: project.findProperty(name)?.toString()
        ?: System.getenv(name) ?: "").trim()

android {
    defaultConfig {
        buildConfigField(
            "String", "APP_SERVICES_ENDPOINT_URL",
            "\"${cblProp("cbl.endpointUrl")}\""
        )
    }
    buildFeatures { buildConfig = true }   // REQUIRED under AGP 8+ — BuildConfig is off by default
}
```

**In `local.properties`** (the provisioning script writes this line automatically):

```properties
cbl.endpointUrl=wss://PLACEHOLDER.apps.cloud.couchbase.com:4984/PLACEHOLDER
```

**In `AppConfig.kt`** — read and validate it:

```kotlin
val appServicesEndpointURL: String
    get() = BuildConfig.APP_SERVICES_ENDPOINT_URL.also {
        require(it.isNotBlank() && !it.contains("PLACEHOLDER")) {
            "APP_SERVICES_ENDPOINT_URL not set. Run setup-capella.sh, then re-sync Gradle."
        }
    }
```

**Script auto-updates `local.properties`** — `setup-capella.sh` detects an Android project (a `local.properties` next to a `settings.gradle(.kts)`, no iOS `Info.plist`) and writes the resolved `wss://` URL to the `cbl.endpointUrl` key. After it runs, the user must **re-sync Gradle** so `BuildConfig` regenerates with the real URL. See `assets/config-keys.md`.

> Do **not** hardcode the URL in Kotlin source, and do not commit a real endpoint to `local.properties` — that file is developer-local by convention (already in the default `.gitignore`).

---
