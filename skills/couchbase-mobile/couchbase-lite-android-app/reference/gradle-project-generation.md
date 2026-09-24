## Generating the Gradle Project (REQUIRED — do this automatically)

**Never ask the user to create the Android Studio project manually.** Generate a complete, buildable Gradle project yourself.

> 📖 **Reference repository for build and dependency settings (use this when in doubt):**
> https://github.com/couchbase-examples/couchbase-lite-retail-demo/tree/main/Android
>
> The official multi-platform demo. Its `/Android` app is the verified reference for Gradle wiring (repositories, the CBL dependency line, Compose setup, `buildConfig`/`buildConfigField`). Check it before guessing a build setting. (It uses the **Enterprise** coordinate (`couchbase-lite-android-ee-ktx`) + the custom Couchbase Maven repo -- the same as this skill's default — see `installation-and-config.md`.)

**MANDATORY CODE-GENERATION RULES — apply to every file you write:**

0. **Use current Couchbase Lite 4.x APIs — NEVER a deprecated or removed one.** Before emitting any CBL call, confirm it against (a) the **reference app** (couchbase-examples/couchbase-lite-retail-demo `/Android`, "GroceryApp" — it targets CBL 4.1.0 EE and is the ground truth for how the current API is actually used) and (b) the **official API docs** at https://docs.couchbase.com/couchbase-lite/current/android/ (and the versioned API reference https://docs.couchbase.com/mobile/4.1.0/couchbase-lite-android/). When in doubt, fetch the docs — do NOT emit an API from memory. **Compatibility floor:** generated code must COMPILE across the full supported CBL range — currently **3.3.x through 4.x** — so never use an API introduced after the floor or removed before the ceiling. **Logging:** use `LogSinks.get().setConsole(ConsoleLogSink(LogLevel.VERBOSE))` — the `LogSinks` API exists from **3.3.x through 4.x**; do NOT use the old `Database.log.console` (removed in 4.0). **Mind the package:** `LogSinks`/`ConsoleLogSink` are in `com.couchbase.lite.logging`, while `LogLevel`/`LogDomain` are in `com.couchbase.lite` — importing `LogSinks` from `com.couchbase.lite` gives "unresolved reference 'LogSinks'". **CRUD** is collection-based — `collection.getDocument(...)` / `collection.save(...)`, never `Database.getDocument(...)`. **Replication** — construct `ReplicatorConfiguration(setOf(CollectionConfiguration(coll1), CollectionConfiguration(coll2)), endpoint)` then set `type`/`isContinuous`/`authenticator`. The `ReplicatorConfiguration(endpoint)` + `addCollection(...)` + no-arg `CollectionConfiguration()` forms were REMOVED in 4.1 (compile on 3.x but NOT 4.1); `CollectionConfiguration(collection)` and the `ReplicatorConfiguration(Collection<CollectionConfiguration>, Endpoint)` constructor exist in both 3.3.x and 4.1.x. **Fallback exception:** when the user has chosen the **CBL 3.2.4 / minSdk 22 fallback** (see `installation-and-config.md`), use the *old* `ReplicatorConfiguration(endpoint)` + `addCollection(...)` form instead — that is the only Replicator wiring 3.2.4 has. Never mix the two forms in one generated app; see `cbl-kotlin-apis.md`'s 3.2.4 fallback snippet. **Status type:** `change.status` is the standalone `ReplicatorStatus` class (NOT nested — this is the opposite of iOS/Swift's nested `Replicator.Status`; verified against the current Android docs, see `cbl-kotlin-apis.md`). If a snippet in this skill ever fails to compile against 4.x, treat it as a skill bug: fix it against the docs + reference app.


1. **`CouchbaseLite.init(context)` runs once in `Application.onCreate()`** before any DB access — and register the custom `Application` subclass with `android:name` in the manifest. Without init, the first `Database(...)` call throws. Enable verbose console logging in `BuildConfig.DEBUG` here via `LogSinks.get().setConsole(ConsoleLogSink(LogLevel.VERBOSE))` (filter Logcat by "CouchbaseLite") — see `cbl-kotlin-apis.md` for the exact `com.couchbase.lite.logging` imports.

2. **`INTERNET` permission in the manifest** — `<uses-permission android:name="android.permission.INTERNET" />`. Without it the replicator silently fails to connect.

3. **`buildFeatures { buildConfig = true }`** in `app/build.gradle.kts` — AGP 8+ generates `BuildConfig` only when this is set. The endpoint URL is read from `BuildConfig` (see `installation-and-config.md`), so omitting this breaks the build with "unresolved reference: APP_SERVICES_ENDPOINT_URL".

4. **Passwords are `CharArray`** — `BasicAuthenticator(username, password.toCharArray())`, never a `String`.

5. **`CouchbaseLiteException` is checked** — wrap every CBL call (open, CRUD, query, index, replicator config) in `try/catch` or mark the function `@Throws`. Surface errors into UI state, don't swallow them.

6. **Credentials via the Android Keystore, never plain `SharedPreferences`/`DataStore`** — use the drop-in `assets/CredentialStore.kt` (AES-GCM, Keystore-wrapped). Store the password on login; the in-session Reconnect / Offline toggle uses the **in-memory** credentials from the current login. Do **not** use the deprecated `EncryptedSharedPreferences`.

6a. **ALWAYS show the Login screen on cold start — NO silent auto-login.** `AppRoot` must NOT auto-restore a session from stored credentials (no `tryRestore()`/`LaunchedEffect` that flips `isLoggedIn` on launch). Offline-first is provided by the **local Couchbase Lite database persisting on disk** — after the user logs in again their data is already there and sync resumes — NOT by skipping the Login screen. This keeps multi-user / two-emulator testing clean: each device shows Login and signs in as its own App User. (A "remember me" auto-login may be added later as an explicit opt-in, off by default.)

7. **Named scope only** — `db.createCollection(name, "warehouse")`, never the `_default` scope.

8. **Live queries collected in `viewModelScope`; every `ListenerToken` removed in `onCleared()`.** A `queryChangeFlow()`/`replicator.addChangeListener` that outlives its ViewModel leaks. Post results to a `StateFlow`; collect Flows with `.flowOn(Dispatchers.IO)` and update state on the main dispatcher.

9. **Offline-mode toggle — a `ReplicationManager` with distinct `pause()` / `stop()` / `start()`, bound to observable state (not local Compose state).**
   - `pause()` — user-initiated offline simulation. Sets `isManuallyPaused = true`, stops the replicator, sets status `OFFLINE`. Does **not** clear `isManuallyPaused` (that's `start()`'s job).
   - `stop()` — logout/cleanup only. Clears `isManuallyPaused = false`, stops, sets status `STOPPED`.
   - `start()` — clears `isManuallyPaused = false`, stops any existing replicator first (no duplicates), then creates & starts.

   ```kotlin
   private val _isManuallyPaused = MutableStateFlow(false)
   val isManuallyPaused: StateFlow<Boolean> = _isManuallyPaused.asStateFlow()

   fun pause() { _isManuallyPaused.value = true;  replicator?.stop(); replicator = null; _status.value = SyncStatus.OFFLINE }
   fun stop()  { _isManuallyPaused.value = false; replicator?.stop(); replicator = null; _status.value = SyncStatus.STOPPED }
   ```

   The Settings switch **binds to `replication.isManuallyPaused` (a StateFlow), not a local `remember { mutableStateOf(...) }`** — a local copy resets when the Settings screen leaves composition, showing "Online" while the replicator is stopped, with no way back. (Same class of bug as the iOS `@State`-resets-on-sheet-dismiss issue.)

10. **`@Composable` toolbars/scaffolds** — use Material 3 `TopAppBar` inside `Scaffold`; the sync-status indicator (color by state) and the settings action live in the app bar's `actions`. Turn the settings icon red on sync error so problems are visible without opening Settings. **`TopAppBar` is an experimental Material 3 API — any `@Composable` that uses it needs `@OptIn(ExperimentalMaterial3Api::class)` on the function, or it's a compile error** (`diagnostics-view.md`'s `SettingsScreen` already does this correctly — every list-screen composable with a `TopAppBar` needs the same annotation, not just the settings screen).

11. **Always generate a `SettingsScreen`** — essential for debugging sync (see `diagnostics-view.md`): signed-in username & role; sync status with colored icon; last error with hints (401 → credentials; 404/connection → endpoint URL / endpoint Online?); the endpoint URL (selectable); scope & collection names; local document count; **Offline-First Demo toggle** (binds to `isManuallyPaused`, rule 9); Reconnect; Sign Out. **The screen MUST be vertically scrollable (`Column(Modifier.verticalScroll(rememberScrollState()))`) with Sign Out pinned in the `Scaffold` `bottomBar`** so it is never clipped off-screen — see `diagnostics-view.md`.

The project structure to generate (Kotlin DSL, single-module app):

```
<AppName>/
├── settings.gradle.kts
├── build.gradle.kts                    ← root (plugins block, versions)
├── gradle.properties                   ← org.gradle.jvmargs, android.useAndroidX=true
├── gradle/wrapper/gradle-wrapper.properties   ← pin Gradle 8.x
├── gradlew  /  gradlew.bat             ← wrapper scripts (mark gradlew executable)
├── local.properties                    ← cbl.endpointUrl (script writes it; git-ignored)
└── app/
    ├── build.gradle.kts                ← plugins, android{}, buildConfigField, deps
    ├── proguard-rules.pro
    └── src/main/
        ├── AndroidManifest.xml         ← INTERNET perm + android:name=".<AppName>Application"
        ├── java/com/couchbase/<appname>/
        │   ├── <AppName>Application.kt  ← CouchbaseLite.init + debug logging
        │   ├── MainActivity.kt          ← setContent { AppTheme { AppNav() } }
        │   ├── AppConfig.kt             ← scope/collections/channel/manager + endpoint from BuildConfig
        │   ├── auth/AuthState.kt        ← isAdmin == AppConfig.managerUsername; Keystore-backed
        │   ├── data/CredentialStore.kt  ← from assets/ (Keystore AES-GCM)
        │   ├── data/DatabaseManager.kt  ← init/open, both collections in named scope, indexes, live queries
        │   ├── data/ReplicationManager.kt ← replicator, pause/stop/start, status StateFlow
        │   ├── model/Movement.kt        ← domain record (Admin-Assigns)
        │   ├── model/StockItem.kt       ← shared reference
        │   └── ui/
        │       ├── LoginScreen.kt
        │       ├── <Domain>ListScreen.kt
        │       ├── <Domain>DetailScreen.kt
        │       ├── StockListScreen.kt
        │       ├── SettingsScreen.kt    ← always include
        │       └── theme/ (Color.kt, Theme.kt, Type.kt)
        └── res/
            ├── values/strings.xml, themes.xml
            └── mipmap-*/ic_launcher (or a single adaptive icon)
```

### `settings.gradle.kts` — repositories

Enterprise Edition resolves from the custom Couchbase Maven repo -- add it in `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories { google(); mavenCentral(); maven { url = uri("https://mobile.maven.couchbase.com/maven2/dev/") } }   // EE resolves from the Couchbase Maven repo
}
rootProject.name = "<AppName>"
include(":app")
```

### `app/build.gradle.kts` — the essentials

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")   // Kotlin 2.0+ Compose compiler
}
android {
    namespace = "com.couchbase.<appname>"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.couchbase.<appname>"
        minSdk = 24; targetSdk = 35   // Default (CBL 4.x). Fallback: minSdk = 22 + couchbase-lite-android-ee-ktx:3.2.4 -- see installation-and-config.md
        versionCode = 1; versionName = "1.0"
        buildConfigField("String", "APP_SERVICES_ENDPOINT_URL", "\"${cblProp("cbl.endpointUrl")}\"")
    }
    buildFeatures { compose = true; buildConfig = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_1_8; targetCompatibility = JavaVersion.VERSION_1_8 }
    kotlinOptions { jvmTarget = "1.8" }
}
dependencies {
    // Fallback: "com.couchbase.lite:couchbase-lite-android-ee-ktx:3.2.4" + minSdk = 22 above -- see installation-and-config.md
    implementation("com.couchbase.lite:couchbase-lite-android-ee-ktx:4.1.0")
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")
    implementation("androidx.navigation:navigation-compose:2.8.0")
}
```

(`cblProp(...)` helper defined at the top of the file — see `installation-and-config.md`.)

### `.run/app.run.xml` — ship a ready-to-run configuration (REQUIRED)

Android Studio only auto-creates the **app** run configuration *after* a successful Gradle sync — so a freshly opened project (before the first clean sync) shows **"Add Configuration" / "No run configurations added"**, and the user is stuck with no obvious Run target. Avoid that entirely: **generate a shareable run configuration as part of the project**, so the **app** target is present the moment the project opens.

Write this file at `<AppName>/.run/app.run.xml` (substitute `<AppName>` for the real project name — it is the Gradle root project name from `settings.gradle.kts`, i.e. the module reference is `<AppName>.app.main`):

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="app" type="AndroidRunConfigurationType" factoryName="Android App">
    <module name="<AppName>.app.main" />
    <option name="DEPLOY" value="true" />
    <option name="DEPLOY_APK_FROM_BUNDLE" value="false" />
    <option name="DEPLOY_AS_INSTANT" value="false" />
    <option name="ARTIFACT_NAME" value="" />
    <option name="PM_INSTALL_OPTIONS" value="" />
    <option name="ALL_USERS" value="false" />
    <option name="ALWAYS_INSTALL_WITH_PM" value="false" />
    <option name="CLEAR_APP_STORAGE" value="false" />
    <option name="DYNAMIC_FEATURES_DISABLED_LIST" value="" />
    <option name="ACTIVITY_EXTRA_FLAGS" value="" />
    <option name="MODE" value="default_activity" />
    <option name="TARGET_SELECTION_MODE" value="DEVICE_AND_SNAPSHOT_COMBO_BOX" />
    <method v="2">
      <option name="Android.Gradle.BeforeRunTask" enabled="true" />
    </method>
  </configuration>
</component>
```

Notes:
- `.run/*.run.xml` is JetBrains' **shareable** run-configuration format (portable, meant to be committed) — unlike `.idea/workspace.xml`, which is per-user and gitignored. Do NOT put the run config in `.idea/`.
- The `<module name="<AppName>.app.main" />` value must match the Gradle root project name (`rootProject.name` in `settings.gradle.kts`) followed by `.app.main`. If the module is named other than `app`, adjust accordingly.
- This config still only *resolves* (turns from a red error into a runnable target) after Gradle sync succeeds — but it means the **app** entry is already in the dropdown, so the user runs it instead of hunting for "Add Configuration". If it shows an unresolved-module error, that means Gradle sync has not completed (fix the Gradle JVM / SDK first, then sync).

### After generating everything, tell the user exactly this:

> **First build steps — do these in order:**
>
> 1. **Open the ROOT `<AppName>` folder**: **File → Open → select the `<AppName>` folder** (the one with `settings.gradle.kts` and `app/`) — not a subfolder, not a single file. Android Studio imports it as a Gradle project. (Coming from Xcode: like opening the project root, not one source file.)
> 
> 2. **First run / no Android SDK yet?** If Android Studio prompts **"Select SDKs — provide the path to the Android SDK"**, no SDK is installed. Install it **through Android Studio**, not a manual download: first-launch **Setup Wizard → Standard**, or **SDK Manager** (Welcome → *More Actions → SDK Manager*, or *Settings → Languages & Frameworks → Android SDK*) → **SDK Platforms: Android 15 (API 35)** + **SDK Tools: Build-Tools, Platform-Tools, Emulator** → **Apply** (installs to `~/Library/Android/sdk`). Don't paste a web URL into that dialog.
> 3. **Fix the Gradle JDK** (the #1 first-build gotcha). This project pins **Gradle 8.9**, which per Gradle's own compatibility table can only run on **JDK 17-22** (JDK 23 needs Gradle 8.10+, 24 needs 8.14+, 25 needs 9.1.0+ -- confirmed against the `gradle/gradle` repo's compatibility doc, not just "avoid as a precaution"). Android Studio's default JDK for new setups is often newer than that, so this commonly surfaces one of two ways:
>    - **Most likely, right when you open the project in step 1 — before any sync error:** a modal titled **"Please Select Gradle JVM to Import Project"**, saying *"The project's Gradle version Gradle 8.9 is incompatible with the Gradle JVM version <N>. To fix this, select a JVM version that is at least 8 and at most 22"*, with buttons **"Open JVM settings"** / **"Use JVM <N>"**. **Just click "Use JVM <N>"** — Android Studio only offers a compatible JDK on this button, so it's always safe to take. One click, done, no need to open Settings.
>    - **Otherwise, after a sync attempt:** the sync fails with **"Incompatible Gradle JVM version" / "Gradle 8.9 requires Java ..."**. Click **"Apply compatible Gradle JDK configuration and sync"** in that error. Android Studio downloads a compatible JDK (e.g. 21) and re-syncs automatically. Done.
>    - **Manual alternative:** **Settings/Preferences → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK** (the current official name, per developer.android.com/build/jdks) → pick the **embedded JDK / JetBrains Runtime (`jbr-…`)** bundled with Android Studio, or the **`GRADLE_LOCAL_JAVA_HOME`** macro (Google's own default/recommended option -- it resolves to the bundled JetBrains Runtime via `.gradle/config.properties`, so seeing that name instead of a plain "JetBrains Runtime NN" entry is normal, not a different setting) — **17 through 22 all work**; avoid a resolved path pointing at a standalone **JDK 23/24/25** → **Apply / OK** → **File → Sync Project with Gradle Files**.
>    - **Not the same thing:** Android Studio Panda 1 (Feb 2026)+ can default new projects to a different feature, **"Gradle Daemon JVM criteria"** — but that only activates for projects on **Gradle 9.2+**, and this project pins Gradle 8.9, so it never applies here. If you see a version-picker UI instead of the plain `Gradle JDK` dropdown, you're looking at an unrelated project or a stale suggestion — use the dropdown above.
>
> 4. Let it **sync Gradle** (downloads CouchbaseLite + Compose, ~1–2 min).
> 5. Create/pick an **emulator** (Device Manager → add a Pixel, API 34/35) — you'll want **two** for the offline-sync test.
> 6. In the toolbar target dropdown, select the pre-created **app** run configuration (shipped in `.run/app.run.xml`), pick your emulator, and click **Run ▶** (or `./gradlew installDebug`). If the dropdown still shows "Add Configuration", your Gradle sync has not finished — see the troubleshooting note below.
>
> **While Gradle syncs**, run `setup-capella.sh` to provision your backend (20–45 min). It writes the real WSS URL into `local.properties` — after it finishes, **re-sync Gradle** so `BuildConfig` picks up the URL.

> **If sync/replication fails with "APP_SERVICES_ENDPOINT_URL not set":** the script hasn't written `cbl.endpointUrl` yet (or you didn't re-sync Gradle after it did). Run the script, then Gradle sync again.

> **If sync fails with "Incompatible Gradle JVM version" / "Gradle 8.9 requires Java …" / "Unsupported class file major version" / invalid `org.gradle.java.home`:** Android Studio is running Gradle on too-new a JDK (commonly 23+). **Fastest fix: click the "Apply compatible Gradle JDK configuration and sync" link shown right in the sync error** — Android Studio downloads a compatible JDK (e.g. 21) and re-syncs for you. Otherwise set it manually: **Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK** → the embedded JDK / JetBrains Runtime (`jbr-…`) or the `GRADLE_LOCAL_JAVA_HOME` macro, resolved to **17-21** → **File → Sync Project with Gradle Files**. Gradle 8.9 (this project's pin) supports **JDK 17-22 only**, confirmed against Gradle's compatibility table — 23 needs Gradle 8.10+, 24 needs 8.14+, 25 needs 9.1.0+.

> **If Android Studio asks for the Android SDK path ("Select SDKs") or a fresh install has no SDK:** install it **via Android Studio** (Setup Wizard → **Standard**, or **SDK Manager** → SDK Platforms **API 35** + SDK Tools **Build-Tools / Platform-Tools / Emulator** → Apply, default `~/Library/Android/sdk`) — NOT a hand-downloaded command-line-tools ZIP. That popup just means no SDK is installed yet.

> **If the toolbar shows "Add Configuration" / the Run/Debug dialog says "No run configurations added":** the generated project ships `.run/app.run.xml`, so an **app** entry should already be in the dropdown — but Android Studio only makes it *runnable* after a successful Gradle sync. So this almost always means **Gradle sync hasn't finished** (set the Gradle JVM to the embedded JBR and install API 35 first, then **File → Sync Project with Gradle Files**). After a clean sync the **app** target is selectable — pick it and Run ▶. If it is still absent after a successful sync, add it by hand: **Run → Edit Configurations → ＋ → Android App**, Name `app`, **Module: `<AppName>.app.main`** (the Module dropdown is empty until sync succeeds), Apply → OK.

### Headless build (for automated verification)

`./gradlew assembleDebug` builds the debug APK to `app/build/outputs/apk/debug/`. Needs JDK 17 and the Android SDK (`ANDROID_HOME` set; `platform-tools`, `platforms;android-35`, `build-tools;35.0.0` installed via `sdkmanager`). This compiles the project without an emulator — the fastest correctness check. See `testing-offline-sync.md` for the on-emulator flow.

---
