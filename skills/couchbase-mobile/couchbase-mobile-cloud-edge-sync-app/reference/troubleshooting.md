## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| App crashes on launch with fatalError | `AppServicesEndpointURL` not set in `Info.plist` (still the `wss://PLACEHOLDER…` value) | Run `setup-capella.sh` (it writes the key via `plutil`), or set `AppServicesEndpointURL` in `Info.plist` manually. Do **not** use a separate `Config.plist` |
| `Library not loaded: CouchbaseLiteSwift.framework` (esp. when launched by tapping the icon / on the 2nd simulator) | The framework isn't embedded for **standalone launch** — so the app only runs while Xcode is attached | Apply the embedding fix: `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")` (Debug+Release) + the empty Embed Frameworks phase; also File → Packages → Resolve Package Versions → Cmd+Shift+K → Cmd+R. **Once embedded, tapping the icon to launch standalone works** — that's exactly what the two-simulator test relies on. |
| Replicator status: stopped with 401 | Wrong credentials | Verify App Services username/password |
| Replicator status: stopped with 404 | Wrong endpoint name in URL | Check URL includes endpoint name after `/4984/` |
| Documents not syncing to user | Channel mismatch | Username must exactly match assignee/channel value; check user has channel access in App Services |
| Sync function `requireRole` never matches | Using wrong prefix — `requireRole("role:admin")` does not work in App Services | Use `requireRole("admin")` — no `role:` prefix in `requireRole()` |
| Admin user never receives documents | Used `access("role:admin", "admin")` in ACF — this grants a fictional user named `"role:admin"`, not the admin role | Remove this line. Grant admin channel access via `admin_channels: ["admin"]` (or `["*"]`) at user creation in the Admin REST API |
| Sync function throws "forbidden" unexpectedly | Using `doc` instead of `oldDoc` for stable fields | Read `assignee`, `owner` from `oldDoc` on update |
| Admin user can't see documents they didn't create | Admin channel not seeded on the role | Set the admin channel on the **admin App Role** via `collection_access` (named scopes require it — flat `admin_channels` is ignored): `POST /_role/ {"name":"admin","collection_access":{"<scope>":{"<collection>":{"admin_channels":["admin"]}}}}`, not on the user. Manager inherits it via `admin_roles:["admin"]`. |
| Field worker receives documents not assigned to them | `requireAccess` channel name doesn't match `channel()` call | Channel strings in `channel()` and `requireAccess()` must be identical |
| App Services takes too long | Normal provisioning time | 5–25 min is expected; do iOS setup while waiting |
| `setup-capella.sh` exits with HTTP 403 | API key lacks Organization Owner role | Regenerate the key with the correct role |
| `setup-capella.sh` exits with HTTP 422 | Invalid request body (region, CIDR conflict) | Change `CLOUD_REGION` or check if a free-tier cluster already exists in the project |
| `jq: command not found` | jq not installed | `brew install jq` |
| Mobile app users can't authenticate | Users created with wrong channel name | `admin_channels` in the user creation call must exactly match the username |
| Offline toggle shows "Online" after re-opening Settings, but sync is still stopped | `@State private var simulatingOffline` resets when the sheet is dismissed | Use `Binding(get:set:)` bound to `replication.isManuallyPaused` (singleton) — see iOS code gen Rule 8 |
| Going back "Online" has no effect after dismissing/reopening Settings | Same root cause as above — `@State` reset means toggle was at `false`, tapping it called `stop()` (no-op) not `reconnect()` | Same fix — bind to singleton state |
| Channels not applied to role/user even though script reports 201 success | Flat `admin_channels` at top level is silently ignored by App Services with named scopes | Use `collection_access` format: `{"collection_access":{"scope":{"collection":{"admin_channels":[...]}}}}` |
| Script creates the endpoint but **no App Users** (users step fails with 401) | **401 = the Admin Credential's stored password differs from `APPSVC_ADMIN_PASS` in your `provision.env`.** A credential with that name already existed in the App Service (e.g. from earlier testing) and was created with a *different* password. The password from your `.env` is only written when the credential is *created* — a "skip if exists" would leave the old password in place, and the API can't read it back to compare or update it. (If the existing credential genuinely had the *same* password, there'd be no 401.) | Use a **unique** `APPSVC_ADMIN_USER` (e.g. `<endpoint>admin`), and note the current script **delete-and-recreates** the app-specific credential each run so its password always equals `provision.env` — this also covers rotating `APPSVC_ADMIN_PASS` between runs. If a generic `admin` was created by hand earlier, use a unique name or delete it in Capella UI (App Services → your service → Admin Users). |

---

