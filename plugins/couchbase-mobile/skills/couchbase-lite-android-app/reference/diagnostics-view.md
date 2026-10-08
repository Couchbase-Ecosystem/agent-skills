## Settings / Diagnostics Screen (ALWAYS include in generated apps)

Every generated app must include a `SettingsScreen` reachable from the main list. It is essential for debugging sync — without it, users have no way to see why sync isn't working.

**The settings icon in the app bar turns red automatically on a sync error**, so users see something is wrong without knowing where to look.

**Minimum content:**

> **The screen MUST be vertically scrollable, and Sign Out MUST be reachable without scrolling.** Put the content in a `Column(Modifier.verticalScroll(rememberScrollState()))` and pin **Sign Out** in the `Scaffold` `bottomBar` (full-width, `error` color). A plain non-scrolling `Column` clips the bottom controls off-screen on shorter devices/emulators — users then cannot log out. (Same fix applies to the iOS diagnostics view — use a `ScrollView`/`List` and keep Sign Out visible.)

```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    authState: AuthState,
    replication: ReplicationManager,
    onClose: () -> Unit,
) {
    val status by replication.status.collectAsStateWithLifecycle()
    val lastError by replication.lastError.collectAsStateWithLifecycle()
    val paused by replication.isManuallyPaused.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings & Diagnostics") },
                navigationIcon = { IconButton(onClick = onClose) { Icon(Icons.Filled.ArrowBack, "Back") } },
            )
        },
        // Sign Out is pinned in the bottom bar so it is ALWAYS visible — never clipped below the fold.
        bottomBar = {
            Column(Modifier.padding(16.dp)) {
                Button(
                    onClick = { authState.logout() },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Sign Out") }
            }
        },
    ) { padding ->
        // MUST be scrollable — the content is taller than the screen. A plain Column clips the
        // bottom items so the user cannot reach them. verticalScroll makes everything reachable.
        Column(
            Modifier
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
        // User
        ListItem(headlineContent = { Text("Username") }, trailingContent = { Text(authState.username) })
        ListItem(headlineContent = { Text("Role") },
                 trailingContent = { Text(if (authState.isAdmin) "manager (admin)" else "regular user") })

        // Sync status — color by state (green=IDLE, orange=CONNECTING, blue=BUSY, grey=OFFLINE, red=error)
        ListItem(
            headlineContent = { Text("Sync") },
            leadingContent = { Icon(status.icon, null, tint = status.color) },
            trailingContent = { Text(status.label) },
        )

        // Error detail with hints
        lastError?.let { err ->
            Text(err, color = MaterialTheme.colorScheme.error)
            if ("401" in err || "unauthorized" in err.lowercase())
                Text("→ Check username/password match App Services App User credentials")
            if ("404" in err || "connect" in err.lowercase())
                Text("→ Check the endpoint URL and that the App Endpoint is Online")
        }

        // Connection details (endpoint URL selectable for copy-paste debugging)
        SelectionContainer { Text(AppConfig.appServicesEndpointURL) }
        ListItem(headlineContent = { Text("Scope") }, trailingContent = { Text(AppConfig.scopeName) })
        ListItem(headlineContent = { Text("Collections") },
                 trailingContent = { Text("${AppConfig.movementsCollection}, ${AppConfig.stockCollection}") })
        ListItem(headlineContent = { Text("Local documents") }, trailingContent = { Text("${replication.localDocCount}") })

        // Offline-First Demo toggle — binds to the SINGLETON's isManuallyPaused (NOT local state)
        ListItem(
            headlineContent = { Text(if (paused) "Offline (simulated)" else "Online") },
            leadingContent = { Icon(if (paused) Icons.Default.CloudOff else Icons.Default.Cloud, null) },
            trailingContent = {
                Switch(checked = !paused, onCheckedChange = { online ->
                    if (online) replication.reconnect() else replication.pause()
                })
            },
        )

        // Actions — Reconnect here; Sign Out is pinned in the bottomBar above.
        Button(
            onClick = { replication.reconnect() },
            modifier = Modifier.fillMaxWidth().padding(16.dp),
        ) { Text("Reconnect") }
        }
    }
}
```

**Trigger from the main list app bar** — the icon turns red on sync error:

```kotlin
TopAppBar(
    title = { Text("Movements") },
    navigationIcon = { SyncStatusIndicator(status) },   // small colored dot/icon
    actions = {
        if (authState.isAdmin) IconButton(onClick = onCreate) { Icon(Icons.Default.Add, "New") }
        IconButton(onClick = onOpenSettings) {
            val err = status.isError
            Icon(
                if (err) Icons.Default.CloudOff else Icons.Default.Settings,
                contentDescription = "Settings",
                tint = if (err) MaterialTheme.colorScheme.error else LocalContentColor.current,
            )
        }
    },
)
```

**Store credentials securely in the Android Keystore** (`assets/CredentialStore.kt`, AES-GCM). The app **always shows Login on cold start** (no auto-login — see gen Rule 6a); in-session **Reconnect** and the Offline toggle use the current session's in-memory credentials, so no re-login is needed while the app is running.

**The Offline-First Demo toggle is the core value proposition** — pausing/resuming the replicator demonstrates offline-first without changing the emulator's network. When paused: replicator stops, indicator shows "Offline", the user's edits save to the local database instantly. Toggle back: `reconnect()` restarts sync and pending changes flow immediately.

> Bind the switch to `replication.isManuallyPaused` (a `StateFlow`), **not** a local `remember { mutableStateOf(...) }`. A local copy resets when the Settings screen leaves composition — the switch would show "Online" while the replicator is actually stopped, with no way back (the Android analogue of the iOS `@State`-resets-on-dismiss bug).

---
