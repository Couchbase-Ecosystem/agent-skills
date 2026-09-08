## Apple iOS Best Practices (apply to all generated apps)

> Always reference Apple's official documentation when generating iOS code. Key references:
> - SwiftUI data flow: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
> - Concurrency / @MainActor: https://developer.apple.com/documentation/swift/mainactor
> - Keychain Services: https://developer.apple.com/documentation/security/keychain_services
> - Info.plist keys: https://developer.apple.com/documentation/bundleresources/information-property-list
> - Privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
> - async/await: https://developer.apple.com/documentation/swift/concurrency
> - Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines

### Data flow and state management
📖 [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)

Use `@MainActor` on all ViewModel/Manager classes that hold `@Published` properties. This guarantees UI mutations happen on the main thread — required for SwiftUI and CBL live query callbacks:

```swift
@MainActor
class DatabaseManager: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
}
```

For iOS 17+ projects, prefer `@Observable` macro over `ObservableObject` + `@Published`. For iOS 16 target (this skill), use `ObservableObject`.

**Ownership rules** (📖 [State and data flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)):**
- `@StateObject` — view *owns* the object (creates it, survives re-render). Use at the root.
- `@ObservedObject` — view receives the object from a parent (no ownership).
- `@EnvironmentObject` — inject once at the root, any descendant reads it. Use for app-wide singletons like `DatabaseManager`, `ReplicationManager`, `AuthState`.

### Credential storage — always use Keychain
📖 [Keychain Services](https://developer.apple.com/documentation/security/keychain_services) | [Protecting keys with the Secure Enclave](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave)

Never store passwords in `UserDefaults` (unencrypted) or keep them in memory after login. Store the App User's credentials in the iOS Keychain:

```swift
import Security

enum KeychainHelper {
    static func save(password: String, for username: String) {
        let data = password.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      username,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)   // remove any existing entry
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(for username: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      username,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` to prevent iCloud backup and cross-device migration of credentials.

### Async operations — use async/await
📖 [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency) | [Calling Swift async from SwiftUI](https://developer.apple.com/documentation/swiftui/calling-swift-async-from-swiftui)

Prefer `async/await` over callbacks and Combine for all async work. Use SwiftUI's `.task { }` modifier for view-scoped async work (auto-cancelled on disappear):

```swift
// ✅ async/await in SwiftUI
.task {
    do {
        try await authState.login(username: username, password: password)
    } catch {
        errorMessage = error.localizedDescription
    }
}

// ✅ Task{} for imperative async calls
Button("Login") {
    Task {
        try? await authState.login(...)
    }
}
```

### Toolbar — use current placement names

📖 [Toolbar](https://developer.apple.com/documentation/swiftui/toolbar) | [Human Interface Guidelines: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)

`navigationBarLeading` and `navigationBarTrailing` are **deprecated**. Always use:
```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) { ... }    // ✅
    ToolbarItem(placement: .topBarTrailing) { ... }   // ✅
    // NOT .navigationBarLeading / .navigationBarTrailing  ❌
}
```

**Toolbar item rules — follow exactly to avoid `Ambiguous use of 'toolbar(content:)'` compile error:**

SwiftUI's `.toolbar {}` is ambiguous when the builder contains exactly **one** `ToolbarItem` declaration. The type becomes unambiguous as soon as there are **two or more** declarations (even if one is conditional and renders nothing). Always declare two items.

Use semantic placements — `.cancellationAction` (leading) and `.confirmationAction` (trailing) — rather than `.topBarLeading/.topBarTrailing` where possible.

```swift
// ✅ Always two ToolbarItem declarations — type is unambiguous
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Save") { save() }
    }
}

// ✅ Conditional second item still works — TupleContent type is unambiguous
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
    }
    if canEdit {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { save() }
        }
    }
}

// ✅ Modal settings sheet — Close + Done (both dismiss, resolves ambiguity)
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Close") { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Done") { dismiss() }
    }
}

// ✅ List view with leading status + trailing actions
.toolbar {
    ToolbarItem(placement: .topBarLeading) { SyncStatusView() }
    ToolbarItem(placement: .topBarTrailing) {
        HStack {
            if isAdmin { Button { } label: { Image(systemName: "plus") } }
            Button { } label: { Image(systemName: "gearshape") }
        }
    }
}

// ❌ Single ToolbarItem — ALWAYS ambiguous, always a compile error
.toolbar {
    ToolbarItem(placement: .topBarTrailing) { Button("Done") { } }
}
```

### [weak self] in CBL callbacks

Always capture `[weak self]` in live query and replicator listeners to avoid retain cycles:

```swift
todosQueryToken = query.addChangeListener { [weak self] change in
    guard let self else { return }
    // update self.todos
}
```

### Privacy manifest (PrivacyInfo.xcprivacy)
📖 [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) — required for App Store submission from iOS 17+

iOS 17+ App Store submissions require a `PrivacyInfo.xcprivacy` file if the app uses covered APIs (`UserDefaults`, file timestamps, etc.). Add one to your Xcode project even if minimal:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
</dict>
</plist>
```

### Mirror the server's access & lock rules on the client (server stays authoritative)

The Access Control Function is the real security boundary — but re-checking its rules on the client gives instant feedback and avoids write-then-reject round-trips. Mirror, don't replace: the server still rejects anything the client misses.

Pattern for locked / immutable documents (e.g. a `closed` task that only an admin may change), applied at three layers:

```swift
// 1. Model — express the rule as data
enum TaskStatus: String, Codable { case pending, inProgress, done, closed
    var isLocked: Bool { self == .closed }        // closed = immutable for non-admins
}

// 2. Database layer — guard before saving (fast local feedback)
func updateTask(_ task: FieldTask) throws {
    guard !task.status.isLocked else { throw DBError.taskLocked }
    // ...save...
}

// 3. UI — make locked state visible and non-editable
private var isReadOnly: Bool { if case .edit(let t) = mode { return t.status.isLocked }; return false }
TextField("Title", text: $title).disabled(isReadOnly)
```

The sync function still enforces the same rule server-side (`if (oldDoc.status === "closed") requireRole("admin")`), so a client that skips the guard cannot bypass it — see `couchbase-mobile-access-control-function/reference/example-comprehensive-access-model.md`.

### Role-gated UI

Show admin-only controls (create, reassign, delete, set `closed`) only to admins; everyone else gets a read/update-own experience. Gate on a single `isAdmin` flag:

```swift
if authState.isAdmin { Button("Delete", role: .destructive) { … } }        // admin-only action
Picker("Status", selection: $status) {
    ForEach(TaskStatus.allCases.filter { $0 != .closed || authState.isAdmin }, …) // hide "closed" from workers
}
```

This is UX only — the server enforces the same via `requireRole("admin")`. For **how to obtain `isAdmin`**, see "Determining the user's role on the client" in the access-model reference.

### App configuration — Info.plist (not a separate file)
📖 [Information Property List](https://developer.apple.com/documentation/bundleresources/information-property-list)

Store endpoint URLs and non-secret config in `Info.plist`. Read at runtime via `Bundle.main.object(forInfoDictionaryKey:)`. The `setup-capella.sh` script updates it automatically via `plutil`. **Do not use a separate Config.plist** — it requires users to create it manually and is not the Apple standard.

---

## iOS Requirements

- Xcode: **26.2+ recommended** (gets Couchbase Lite 4.x, the recommended line); **16.x supported** but pins CBL to the 3.x line (newest — 3.3.0)
- **At least two iOS Simulators** installed (the offline-sync test runs the app on two side by side) — add via Xcode → Window → Devices and Simulators → Simulators → +
- iOS **16+** — this skill's deployment target. (Couchbase Lite itself supports **iOS 15+**; we target 16 for the SwiftUI APIs used here — `ObservableObject` and the iOS-16 single-parameter `onChange` form.)
- Swift 5.9+
- **Couchbase Lite Swift SDK — matched to Xcode (use the newest compatible):** 4.x on Xcode 26.2+ (`couchbase-lite-swift-ee.git`), or newest 3.x — currently **3.3.0** — on Xcode 16.x (`couchbase-lite-ios-ee.git`, pin `upToNextMinor 3.3.0`; fall back to 3.2.4 only if needed). See `installation-and-plist.md`. Never use `from 4.0.3` on Xcode 16.x.
- SwiftUI
- Swift Package Manager for CBL dependency

Default target is the **Simulator** (no code signing). A physical device is optional and requires a Development Team under Signing & Capabilities.

---

