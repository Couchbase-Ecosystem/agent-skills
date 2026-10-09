# Info.plist — keys to add (not a full replacement)

Xcode manages most of `Info.plist` via build settings, so do **not** drop in a full replacement file. Add just the app-specific key below to your target's `Info.plist`. `setup-capella.sh` overwrites the placeholder with the real endpoint via `plutil`.

```xml
<key>AppServicesEndpointURL</key>
<string>wss://PLACEHOLDER.apps.cloud.couchbase.com:4984/PLACEHOLDER</string>
```

Read it at runtime (see `reference/installation-and-plist.md` and `reference/appconfig-swift.md`):

```swift
Bundle.main.object(forInfoDictionaryKey: "AppServicesEndpointURL") as? String
```

Do **not** use a separate `Config.plist` — Info.plist is the Apple-standard location and is always present in the bundle.
