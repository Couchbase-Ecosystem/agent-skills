### Dependency ordering (MUST follow exactly)

The Capella resources have hard dependencies. The script MUST follow this order and wait at each stage:

```
1. Get org ID
2. Create project
3. Create cluster  ← wait healthy (5–25 min) before proceeding
4. Create bucket
5. Create collections
6. Create App Service  ← wait healthy (15–25 min) before proceeding
7. Create App Endpoint  ← only possible after App Service is healthy
```

App Services takes 15–25 min and will not accept an App Endpoint until it is fully healthy. The `wait_for_app_service` call before `create_app_endpoint` is **not optional**.

28. **Access Control Function update is a separate step from endpoint creation.** Always call `update_access_control_functions` after `get_or_create_app_endpoint` — even when the endpoint already exists. This ensures the correct function is always deployed on re-runs.

    **Keyspace format:** `endpointName.scope.collection` (all three parts, dot-separated). Example: `todosync.todo.todos`.

    **Content-Type MUST be `application/javascript`** — NOT `application/json`. Send the raw JavaScript function text as the body. Strip ALL comments before sending (non-ASCII in comments breaks the JS parser).

    **Do NOT use the `api()` helper for this call** — `api()` forces `Content-Type: application/json` which causes a 400 error. Use `curl` directly:

    ```bash
    fn_clean=$(cat "$fn_file" \
      | sed '/^[[:space:]]*\/\*\*/,/\*\//d' \
      | sed 's|[[:space:]]*//.*$||g' \
      | sed '/^[[:space:]]*$/d')
    keyspace="${CB_ENDPOINT_NAME}.${scope}.${collection}"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
      "${BASE_URL}${base_path}/${keyspace}/accessControlFunction" \
      -H "Authorization: Bearer ${CB_API_KEY}" \
      -H "Content-Type: application/javascript" \
      --data-binary "$fn_clean") || true
    # 200/201/204 = success. Any other code = failure.
    ```
    The Access Control Function is loaded from `${SYNC_FUNCTIONS_DIR}/<collection>-sync-function.js`. It must restrict creates to admin App Role only (regular App Users must not be able to create documents):
    ```javascript
    if (!oldDoc) { requireRole("admin"); }   // "admin" = App Role name, not a username
    ```
    Note: `requireRole("admin")` refers to the App Role named `"admin"` — not the App Services Admin Credential. The App User named `manager` holds the `admin` App Role, which is why they can create.

29. **App Services Admin Credential is created via the Capella Management API — no UI step needed.**
    Use `POST .../appservices/{id}/adminUsers` with body:
    ```bash
    {"name":"admin","password":"...","enableBucketLevelAccess":true,"access":{"accessAllEndpoints":true}}
    ```
    This is idempotent — check if the credential already exists before creating. Separate from creating App Users (which uses the Admin REST API after the credential exists).

30. **Allowed CIDR must be set up before calling the Admin REST API.**
    Use `POST .../appservices/{id}/allowedcidrs` with `{"cidr":"0.0.0.0/0","comment":"..."}` for dev/test. Check for existing `0.0.0.0/0` first to stay idempotent.

31. **WSS URL is derived from `publicURL` by swapping scheme only — never append the endpoint name.**
    `publicURL` already includes the endpoint name (e.g. `https://host:4984/todosync`). Just swap the scheme:
    ```bash
    wss_url=$(echo "$public_url" | sed 's|^https://|wss://|')
    # NOT: wss_url="${wss_url%/}/${CB_ENDPOINT_NAME}"  ← causes /todosync/todosync
    ```

32. **Auto-write the WSS URL into `Info.plist`.** The user should not have to paste it. The script auto-finds the app's `Info.plist` and sets the `AppServicesEndpointURL` key with Apple's `plutil` (do **not** write a separate `Config.plist` — Info.plist is the Apple-standard location; see `couchbase-lite-ios-app`):
    ```bash
    info_plist=$(find . -name "Info.plist" \
      -not -path "*/DerivedData/*" -not -path "*/.xcodeproj/*" \
      -not -path "*/.framework/*" -not -path "*/Pods/*" | head -1)
    if [[ -n "$info_plist" ]]; then
      plutil -replace AppServicesEndpointURL -string "$wss_url" "$info_plist" 2>/dev/null || \
        plutil -insert AppServicesEndpointURL -string "$wss_url" "$info_plist"
    fi
    ```

33. **Default App Users — use distinct names to avoid confusion with the Admin Credential:**
    - `manager` (or `MANAGER_USER`) — App User with `admin` App Role. Manages and assigns tasks. Password: `MANAGER_PASS`.
    - `bob` — Default regular App User. Sees only their own assigned tasks. Password: `BOB_PASS`.
    - **Admin Credential** (`APPSVC_ADMIN_USER`) — used only to call the Admin REST API; not an App User, never syncs data.
    In `AppConfig.swift`, use `static let managerUsername = "manager"` and set `isAdmin = (username == AppConfig.managerUsername)`.

    > **⚠️ Admin Credential name MUST be unique per app — do NOT default to `admin`.** App Services Admin Credentials are **App-Services-scoped** (one credential, created with `accessAllEndpoints: true`, covers *all* App Endpoints in that App Service). Their passwords **cannot be read back or updated** via the API (`PUT /adminUsers/{id}` only changes endpoint access). So if a credential named `admin` already exists in the App Service, "skip if exists" leaves its old password in place and later Admin-REST calls fail with **401** (endpoint gets created but **no App Users/Roles**). Two things handle this: (1) set `APPSVC_ADMIN_USER` to an app-specific name (e.g. `<endpoint>admin`); (2) the script **delete-and-recreates** the credential on re-run so its password always matches `APPSVC_ADMIN_PASS` (safe because the name is app-specific). Other resources (App Endpoint, App Users, Roles) are genuinely skip-if-exists / upsert (POST→PUT-on-409); only the credential needs delete-and-recreate, because its password is immutable.

### Idempotency (REQUIRED)

The script must be **safe to re-run**. Every creation step must check if the resource already exists by name before creating it, and reuse if found. Use `get_or_create_*` functions for every resource. Never blindly POST — always list first and filter by name.

Use `api_or_empty()` (returns empty string on 4xx instead of exiting) for existence checks. Use `api()` (exits on error) for actual creates.

Also handle the free-tier cluster **turnedOff** state — see the turnedOff rule (Rule 26) in `role-channel-rules.md` (couchbase-mobile-access-control-function skill).

### What the script does (and does NOT do)

- ✅ **Idempotent** — safe to re-run; skips resources that already exist
- ✅ Creates: project, cluster, bucket, collections, App Service, App Endpoint (with Access Control Functions inline)
- ✅ Creates App Services Admin Credential via Capella Management API — **no manual UI step**
- ✅ Sets up allowed CIDR `0.0.0.0/0` so Admin REST API is accessible from any IP
- ✅ Brings App Endpoint Online, then creates `admin` App Role, `manager` App User (holds the admin role), `bob` App User
- ✅ Auto-writes the WSS endpoint URL into the app's `Info.plist` (`AppServicesEndpointURL` via `plutil`)

### Required env vars

```bash
export CB_API_KEY='your-api-key-secret'
export APPSVC_ADMIN_PASS='Passw0rd!'
export SYNC_FUNCTIONS_DIR='sync-functions'           # resolved relative to the script's location — no project-name prefix
# WSS URL is written automatically to the app's Info.plist (auto-detected) — no plist env var needed.
./setup-capella.sh
```

**Password requirements for `APPSVC_ADMIN_PASS`:**
- Minimum 8 characters, mix of uppercase, lowercase, numbers, special characters
- Single quotes prevent bash expanding `!` as history
- Used for the App Services Admin Credential (the `admin` credential is NOT an App User)

### Script flow (fully automated — no manual UI steps)

1. Provisions infrastructure (cluster → App Service → App Endpoint) — 20–45 min total
2. **Separately updates Access Control Function for every collection** via `PUT .../accessControlFunction` — always runs, even when endpoint already exists, ensuring the correct function is deployed
3. Creates App Services Admin Credential via Capella Management API
4. Sets up allowed CIDR `0.0.0.0/0` on the App Service
5. Brings App Endpoint Online
6. Creates via Admin REST API: `admin` App Role, `manager` App User (admin role), `bob` App User
7. Auto-writes the WSS URL into the app's `Info.plist` (`AppServicesEndpointURL`) — then build & run

**The Access Control Function update (step 2) is a separate step from endpoint creation.** This is critical because on re-runs the endpoint already exists and is skipped — without a separate update step, the function would never be updated. Always structure the script with `get_or_create_app_endpoint` and `update_access_control_functions` as two distinct calls.

### Default users created by the script

| Username | Password | App Role | Channel | Purpose |
|---|---|---|---|---|
| `admin` (credential) | `APPSVC_ADMIN_PASS` | — | — | **App Services Admin Credential** — infrastructure only, not a mobile user |
| `manager` (App User) | `Password1!` | admin | admin | Manages and assigns tasks, sees all documents |
| `bob` (App User) | `Password1!` | — | bob | Default regular App User, sees only their assigned documents |

`MANAGER_USER` (default `manager`) and `BOB_PASS`/`MANAGER_PASS` (default `Password1!`) are overridable env vars. Change default passwords before sharing with real users.

---

