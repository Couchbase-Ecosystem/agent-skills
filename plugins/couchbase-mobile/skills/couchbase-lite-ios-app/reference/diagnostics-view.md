## Settings / Diagnostics View (ALWAYS include in generated apps)

Every generated app must include a `SettingsView` accessible from the main list screen. This is essential for debugging sync issues — without it, users have no way to see why sync isn't working.

**The gear icon turns red automatically when there's a sync error** — users see something is wrong without needing to know where to look.

**Minimum content for the Settings view:**

> **Wrap the content in a `Form` (or `List`) so it scrolls** — a settings screen has more rows than fit on a short device, and a plain `VStack` clips the bottom (including Sign Out) off-screen. `Form`/`List` scroll natively. Keep **Sign Out** (`role: .destructive`) reachable; for extra prominence pin it below the scroll with `.safeAreaInset(edge: .bottom) { Button("Sign Out", role: .destructive){ authState.logout() }.buttonStyle(.borderedProminent).tint(.red).padding() }`.

```swift
// MARK: - User section
LabeledContent("Username", value: authState.username)
LabeledContent("Role", value: authState.isAdmin ? "manager (admin)" : "regular user")

// MARK: - Sync status with color (green=idle, orange=connecting, blue=syncing, red=error)
Image(systemName: replication.syncStatus.systemImage).foregroundStyle(statusColor)
Text(replication.syncStatus.label)

// MARK: - Error detail with hints
if let error = replication.lastSyncError {
    Text(error)  // full error message
    // Check for auth error (401/unauthorized) — most common issue
    if error.contains("401") || error.lowercased().contains("unauthorized") {
        Text("→ Check username/password match App Services App User credentials")
    }
    // Check for network/endpoint error (404/not found)
    if error.contains("404") || error.lowercased().contains("not found") {
        Text("→ Check WSS URL in Info.plist and App Endpoint is Online")
    }
}

// MARK: - Connection details
Text(AppConfig.appServicesEndpointURL.absoluteString)  // shows exact WSS URL being used
LabeledContent("Scope", value: AppConfig.scopeName)
LabeledContent("Collection", value: AppConfig.todosCollection)

// MARK: - Actions
Button("Reconnect") { /* restart replicator */ }
Button("Sign Out", role: .destructive) { authState.logout() }
```

**Trigger from main list toolbar** (📖 [Toolbar — HIG](https://developer.apple.com/design/human-interface-guidelines/toolbars)): gear icon turns red when sync error:
```swift
// Two ToolbarItem declarations — resolves ambiguity (single item always fails)
.toolbar {
    ToolbarItem(placement: .topBarLeading) { SyncStatusView() }
    ToolbarItem(placement: .topBarTrailing) {
        Button { showingSettings = true } label: {
            Image(systemName: replication.syncStatus.isError ? "exclamationmark.icloud" : "gearshape")
                .foregroundStyle(replication.syncStatus.isError ? .red : .primary)
        }
    }
}
```

**Store credentials in the Keychain** (never UserDefaults) — see the `KeychainHelper` in the best-practices section. The app **always shows Login on cold start** (no auto-login — see gen Rule 5a); in-session **Reconnect** uses the current session's credentials, so no re-login while the app is running.

**Always include an Offline-First Demo toggle** — this is the core value proposition of the app. Stopping/starting the replicator demonstrates offline-first without requiring the user to change Wi-Fi settings:

```swift
// Offline-First Demo section in SettingsView.
// Bind to the SINGLETON's isManuallyPaused — NOT a local @State — so the toggle
// reflects real sync state and survives the Settings sheet being dismissed/reopened.
// Use pause()/reconnect(), NOT stop() (stop() is logout-only). See iOS code-gen Rule 8.
Toggle(isOn: Binding(
    get: { replication.isManuallyPaused },
    set: { paused in
        paused ? ReplicationManager.shared.pause()      // offline: stop replicator, keep local DB fully usable
               : ReplicationManager.shared.reconnect()  // online: restart; pending changes sync immediately
    }
)) {
    Label(
        replication.isManuallyPaused ? "Offline (simulated)" : "Online",
        systemImage: replication.isManuallyPaused ? "icloud.slash" : "icloud"
    )
}
```

When paused: replicator stops, sync indicator shows "Offline"; the user's edits save to the local database instantly. Toggle back on: `reconnect()` restarts sync and pending changes flow immediately. This is the offline-first demo in one toggle, no Wi-Fi configuration needed. (Binding-to-singleton is essential — a `@State` copy resets when the sheet closes, which is the bug in troubleshooting rows 20–21.)

---

