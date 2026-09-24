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
- **Default to the latest 4.x** (currently **4.1.0**) — there is no older-toolchain fallback: every AAR from **3.3.3** up (including the 3.4.x line) already declares **minSdk 24** and is built with **AGP 8**, exactly like 4.x, so it doesn't help a team stuck on an old Android Studio/AGP/JDK. **AGP 8 / JDK 17 is a hard requirement for this skill regardless of CBL version** — see the toolchain table below.
- **minSdk-22 fallback — for apps that must run on Android 5.1/6.0 (API 22/23) devices.** The only release with minSdk 22 is **3.2.4**. This is a real, supported option (see `cbl-kotlin-apis.md` for the generated code), not just a documented limitation — but it means generating a genuinely different Replicator setup: 3.2.4 does **not** have the `ReplicatorConfiguration(Collection<CollectionConfiguration>, Endpoint)` constructor or `CollectionConfiguration(collection)` that the 4.x snippets use (verified directly against the versioned 3.2.4 API reference); it uses the older `ReplicatorConfiguration(endpoint)` + `addCollection(collection, config)` form instead. Everything else this skill generates against — collection-based CRUD, `LogSinks` (present since 3.2.2), Live Query, Full-Text Search — is unchanged on 3.2.4. **Not independently verified:** whether 3.2.4 itself needs AGP 8 / JDK 17 to build (Maven Central was unreachable to check the manifest directly) — test this before committing to the fallback for a toolchain-constrained team.

### Toolchain compatibility band

Modern Android Studio bundles the JDK and a compatible AGP, so — unlike iOS, where the Xcode version forces the SDK line — Android is uniformly modern; **always use the latest 4.x** (currently **4.1.0** — pin the newest available, per the confirm-version note at the top of this file). There is no older-toolchain fallback line — see the note above. Requirements:

| Setting | Value |
|---|---|
| `minSdk` | **24** (Android 7.0) by default — the `couchbase-lite-android(-ee)-ktx:4.x` AAR **declares minSdk 24 in its own manifest**, so the project must be >= 24 or the build fails with *"uses-sdk:minSdkVersion 22 cannot be smaller than version 24 declared in library"*. **Every AAR from 3.3.3 up (including 3.4.x) enforces the same minSdk 24** — **3.2.4** is the only release that allows **22**, as a genuine fallback for apps that must reach Android 5.1/6.0 devices (see the fallback note above); choosing it means the older Replicator wiring, not just a version bump. Raise only if your app needs newer APIs. |
| `compileSdk` / `targetSdk` | **35** |
| JDK to run the build | **17** (bundled with Android Studio; required by AGP 8) |
| Source/target compatibility | Java **8** is fine (`VERSION_1_8` / `jvmTarget = "1.8"`) — CBL ships Java-8 bytecode |
| Android Gradle Plugin | **8.x** (e.g. 8.7) |
| Gradle | **8.x** (e.g. 8.9) |
| Kotlin | **2.0+** (Compose apps use the `org.jetbrains.kotlin.plugin.compose` compiler plugin) |

> **Set the Gradle JDK to 17-22 before the first sync -- this project pins Gradle 8.9, which cannot run on anything newer.** Confirmed against Gradle's own compatibility table (gradle/gradle repo, `compatibility.adoc`): support for *running* Gradle on a given JDK is added in a specific Gradle version and holds for every later one -- JDK 22 needs Gradle >= 8.8, JDK 23 needs >= 8.10, JDK 24 needs >= 8.14, JDK 25 needs >= 9.1.0. Since this project is pinned to **8.9**, it satisfies only the JDK-22 line and below -- **JDK 17 through 22 all work, 23/24/25 do not** (not just "avoid as a precaution" -- Gradle 8.9 genuinely cannot execute on them).
>
> **The setting is officially named `Gradle JDK`** (confirmed via developer.android.com/build/jdks, current across recent Android Studio versions): **Settings/Preferences → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK**. Its dropdown offers: macros `JAVA_HOME` and `GRADLE_LOCAL_JAVA_HOME`; JDK table entries in `vendor-version` form like `jbr-17`; downloading a JDK; adding a specific JDK; and locally detected JDKs. **`GRADLE_LOCAL_JAVA_HOME` is the default for newly created projects and Google's own recommendation** -- it reads the `java.home` property in `.gradle/config.properties`, which itself defaults to the bundled JetBrains Runtime. So a dropdown reading `GRADLE_LOCAL_JAVA_HOME -> JetBrains Runtime NN` is normal, expected, Google-recommended behavior, not an edge case -- don't second-guess the label, just check the **resolved path** shown with it: `.../jbr-17.../Contents/Home` through `.../jbr-22.../Contents/Home` is correct, leave it; a path resolving to JDK 23/24/25 needs changing to the embedded JBR (17-21 are the safest picks) via the same dropdown.
>
> **On first opening the generated project, Android Studio will very likely show this exact dialog before you ever get to Settings:** a modal titled **"Please Select Gradle JVM to Import Project"** -- *"The project's Gradle version Gradle 8.9 is incompatible with the Gradle JVM version 25. To fix this, select a JVM version that is at least 8 and at most 22"* -- with two buttons, **"Open JVM settings"** and **"Use JVM <N>"** (the number matches whatever compatible JDK Android Studio already has on disk, commonly 21). This fires automatically at project-import time whenever the machine's detected/default JDK (here, 25) falls outside Gradle 8.9's 17-22 window -- it is Android Studio doing the same compatibility check this skill documents, before a sync is even attempted. **The fix is one click: "Use JVM <N>"** -- any version it offers here will be within 17-22 (Android Studio only offers compatible JDKs on this dialog), so there's no need to verify the number or open JVM settings manually. This is equivalent to setting `Gradle JDK` in Settings by hand (previous paragraph) -- just faster, since Android Studio is proposing the fix upfront rather than after a failed sync.
>
> **A separate, newer feature exists but does NOT apply to this project:** Android Studio Panda 1 (Feb 2026) and later default new projects to **"Gradle Daemon JVM criteria"** instead of the `Gradle JDK` dropdown -- auto-detecting or auto-downloading a compatible JDK. It was stabilized in **Gradle 9.2.0**, so it only takes effect for projects on Gradle 9.2+. Since this skill pins **Gradle 8.x**, generated projects never use it, on any Android Studio version -- if something you're reading (including an earlier answer in this conversation) mentions "Default Gradle JVM criteria" or a version-picker UI, that's describing this different, inapplicable feature (and getting its name slightly wrong -- it's "Daemon", not "Default"). Use the plain `Gradle JDK` dropdown above instead.

**AGP 8 / JDK 17 is a hard requirement** for this skill — there's no fallback line that avoids it (3.4.0/3.3.3 need AGP 8 too). If the user is on an older Android Studio/AGP, the fix is to **upgrade Android Studio** (it bundles a compatible JDK and AGP), not to pin an older CBL version.

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
