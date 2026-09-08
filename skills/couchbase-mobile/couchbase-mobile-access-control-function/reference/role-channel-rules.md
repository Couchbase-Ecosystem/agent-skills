### Access Control Function + Role + Channel — Rules Learned From Real Bugs (CRITICAL — apply every time)

These rules apply whenever generating BOTH the ACF file AND the `setup-capella.sh` script. They are listed here because the ACF and the script role setup are tightly coupled — getting one right while getting the other wrong causes silent sync failures that are hard to debug.

**Rule A — NO `role:` prefix anywhere in App Services ACFs.**

> **Deployment-dependent — this is the key gotcha.** The `role:` prefix is **valid on self-managed Sync Gateway (on-prem)**, where `requireRole("role:admin")` and `access("role:admin", ...)` work as intended. It is **NOT supported on Capella App Services**, where the same code silently misbehaves (matches nothing / grants a fictional user). So a sync function copied from an on-prem deployment can look correct and still fail on App Services. Since this skill targets App Services, **drop the `role:` prefix**. If you later deploy the identical function to on-prem Sync Gateway, the prefix is permitted there — but the bare form below also works on both, so prefer it for portability.

On App Services specifically, the `role:` prefix does not exist in ACFs:

```javascript
// WRONG — will never match, silently allows or blocks everything:
requireRole("role:admin")           // ❌ never matches — "role:admin" is not a valid role name
access("role:admin", "admin")       // ❌ grants a user literally named "role:admin" (doesn't exist)

// CORRECT — bare role name, no prefix:
requireRole("admin")                // ✅ matches App Role named "admin"
access(assignee, assignee)          // ✅ grants a real username access to their channel
// DO NOT call access() for roles at all — use admin_channels on the role instead (see Rule B)
```

**Rule B — Admin channel access belongs on the App Role, not in the ACF.**
The ACF has no mechanism to grant channel access to a role. `access()` only works with usernames. The correct place to give admin users access to the "admin" channel is `admin_channels` on the App Role itself:

```bash
# WRONG — access() in ACF with role: prefix does nothing useful:
access("role:admin", "admin")   # ❌ grants fictional user "role:admin", not the role

# CORRECT — set admin_channels on the role via the Admin REST API:
POST /_role/  {"name":"admin","admin_channels":["admin"]}
# Now every user with admin_roles:["admin"] automatically has access to "admin" channel
# The ACF does NOT need an access() call for this — channel access is inherited from the role
```

**Rule C — The ACF and the role's `admin_channels` must be consistent.**
`requireAccess(["admin"])` in the ACF passes only if the user has been granted access to the "admin" channel. That grant comes from `admin_channels` on the role. If the role is missing `admin_channels: ["admin"]`, `requireAccess(["admin"])` will always fail for the manager — even though they have the admin role.

```
ACF:    channel("admin")              ← routes doc to "admin" channel
ACF:    requireAccess(["admin"])      ← gate: user must have "admin" channel access
Role:   admin_channels: ["admin"]     ← THIS is what makes requireAccess pass for manager
User:   admin_roles: ["admin"]        ← user inherits admin_channels from the role
```

If any of these four is missing or wrong, manager cannot see documents. **Always generate all four together.**

**Rule D — Generated ACF template (use verbatim for admin-assigns pattern):**
```javascript
function(doc, oldDoc) {
  if (doc.type == "YOUR_TYPE" || (doc._deleted && oldDoc && oldDoc.type == "YOUR_TYPE")) {
    var assignee = oldDoc ? oldDoc.assignee : doc.assignee;
    if (!assignee) throw({forbidden: "assignee is required"});

    if (!oldDoc)    { requireRole("admin"); }   // create: admin only. NO role: prefix.
    if (doc._deleted) { requireRole("admin"); return; }  // delete: admin only. NO role: prefix.

    // field validation here...

    channel(assignee);   // route to assignee's channel
    channel("admin");    // route to admin channel (Pattern A — matches role admin_channels:["admin"])

    access(assignee, assignee);  // grant assignee their channel dynamically
    // DO NOT add access("role:admin", ...) — admin channel access comes from the role, not here

    requireAccess([assignee, "admin"]);  // passes: assignee has their channel; manager has "admin" via role
  }
}
```

**Rule E — `collection_access` format is REQUIRED for App Services with named scopes.**
The flat `admin_channels: [...]` top-level field is **Sync Gateway pre-collections syntax and is silently ignored by App Services**. Even if the API returns 201/200, the channels will NOT appear in the UI and will NOT take effect. Always use `collection_access` keyed by scope → collection.

```bash
# WRONG — flat admin_channels silently ignored by App Services with named scopes:
POST /_role/  {"name":"admin","admin_channels":["admin"]}   # ❌ channels never applied

# CORRECT — collection_access per scope/collection (scope and collection from COLLECTIONS env var):
POST /_role/  {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["admin"]}}}}
POST /_user/  {"name":"bob","password":"...","collection_access":{"todo":{"todos":{"admin_channels":["bob"]}}}}
POST /_user/  {"name":"manager","password":"...","admin_roles":["admin"]}  # inherits from role — no collection_access needed
```

Build `collection_access` dynamically in the script:
```bash
build_collection_access() {
  local channels_json="$1"   # e.g. '["admin"]' or '["bob"]'
  local ca="{}"
  for pair in $COLLECTIONS; do
    local scope="${pair%%/*}" collection="${pair##*/}"
    ca=$(echo "$ca" | jq --arg s "$scope" --arg c "$collection" --argjson ch "$channels_json" \
      '.[$s][$c].admin_channels = $ch')
  done
  echo "$ca"
}
# Role: admin_ca=$(build_collection_access '["admin"]')
#        role_body=$(jq -n --arg name "admin" --argjson ca "$admin_ca" '{"name":$name,"collection_access":$ca}')
# User:  bob_ca=$(build_collection_access '["bob"]')
#        bob_body=$(jq -n --arg p "$BOB_PASS" --argjson ca "$bob_ca" '{"name":"bob","password":$p,"collection_access":$ca}')
```
Always use POST→PUT-on-409 (see Rule 19). Never POST-only.

**Rule F — the `*` (star) channel for "sees everything" principals.**
`*` means *all channels*: a user or role granted `*` receives documents in every channel. It is never implicit — grant it explicitly. Two valid designs for an all-access admin:

- **Named channel (this skill's default):** route docs with `channel("admin")` and grant the role the `admin` channel (Rules B–E). Explicit about what admins get.
- **Star channel:** grant the role `*` instead — no per-document `channel("admin")` routing needed, admins receive everything. For named scopes, `*` goes inside `collection_access` exactly like any other channel:

```bash
# Admin role that sees ALL documents in the scope/collection via the star channel:
POST /_role/  {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["*"]}}}}
```

Reminder on the two grant mechanisms: `access(user, channel)` **inside the function** is dynamic and per-user (use for `access(assignee, assignee)`); `admin_channels` (in `collection_access`) **at role/user creation** is static and the correct place for role-level and `*` grants. Do not try to grant `*` to a role via `access()` in the function — role grants via `access()` are unreliable on App Services (Rule A/B).

19. **Check for existence before creating every resource — the script must be safe to re-run.** Never blindly POST. For each resource: list first, filter by name, reuse if found, create only if missing. Use `get_or_create_*` functions for every step.

    **Exception for App Roles and App Users**: these use the Admin REST API which returns 409 on POST if the resource already exists. Always follow POST with a PUT on 409 to upsert the correct configuration. A POST-only approach silently leaves stale config on re-runs:
    ```bash
    # WRONG — silently skips update on re-run:
    POST /_role/  {"name":"admin","admin_channels":["admin"]}
    if 409: echo "already exists" && return   # ← never updates existing role

    # CORRECT — PUT on 409 ensures config is always current:
    POST /_role/  {"name":"admin","admin_channels":["admin"]}
    if 409:
      PUT /_role/admin  {"name":"admin","admin_channels":["admin"]}   # upsert
    ```
    This applies to both `/_role/{name}` and `/_user/{name}`. Re-running the script must always leave roles and users in the correct state.

    ```bash
    # Pattern for every resource:
    get_or_create_project() {
      # 1. List existing resources
      local list_resp
      list_resp=$(api GET "/organizations/${org_id}/projects")
      # 2. Filter by name
      local existing_id
      existing_id=$(echo "$list_resp" | jq -r --arg n "$CB_PROJECT_NAME" \
        '.data[]? | select(.name == $n) | .id' | head -1)
      # 3. Reuse if found
      if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
        log "   ♻️  Reusing existing project: $existing_id"
        echo "$existing_id"; return
      fi
      # 4. Create only if missing
      local resp
      resp=$(api POST "/organizations/${org_id}/projects" "$(jq -n --arg n "$CB_PROJECT_NAME" '{"name":$n}')")
      echo "$resp" | jq -r '.id'
    }
    ```

    Use `api_or_empty()` (returns empty string on 4xx, never exits) for existence checks. Use `api()` (exits on HTTP error) for creates.

    Apply this pattern to: project, cluster, bucket, scope, collection, App Service, App Endpoint.

    Also handle the free-tier cluster **turnedOff** state — see Rule 26 below.

20. **Only ONE scope allowed per App Endpoint.** The OpenAPI spec explicitly states "Only one scope is allowed per App Endpoint." All collections in an endpoint must belong to the same named scope. Design your data model accordingly — if you need multiple collections, put them all under one scope (e.g. `fieldops/tasks` and `fieldops/assets`, not `fieldops/tasks` and `other/assets`).

21. **Collections linked to an App Endpoint must have `maxTTL: 0`.** App Services will fail to sync collections that have a non-zero TTL — the TTL causes system `_sync` documents to expire, breaking synchronization. Always create collections with `maxTTL: 0`:
    ```bash
    api POST "${base}/scopes/${scope}/collections" \
      "{\"name\":\"${collection}\",\"maxTTL\":0}" > /dev/null
    ```

22. **Two completely separate "admin" concepts — never confuse them:**

    | | App Services Admin Credential | App user with admin role |
    |---|---|---|
    | What it is | Admin user who invokes the Admin REST API to create App users and roles | Regular App user that syncs data with App Services |
    | Created where | Capella UI → App Services → **Settings → Admin Credentials** | Via Admin REST API after admin credential exists |
    | Syncs data? | No — only for admin operations | Yes — via Couchbase Lite replication |
    | Changeable? | ❌ Username/password cannot be changed after creation | ✅ |
    | `APPSVC_ADMIN_PASS` | This IS the App Services Admin Credential password | `admin` is the Admin Credential only — NOT an App User |

    **The App Services Admin Credential is created automatically by the script** via `POST .../appservices/{id}/adminUsers`. No manual UI step needed. See Rule 28 for the API details.

    The Admin REST API base URL is on port 4985 — find it in:
    App Endpoint → Connect tab → "Connect for Admin REST" section.

23. **Use the `adminURL` from the API response — never hardcode the port.** The admin URL varies by cloud provider (AWS uses port 4985, GCP uses 443, etc.). The App Endpoint GET response includes an `adminURL` field — use it directly. Never construct the admin URL from host + port:
    ```bash
    # WRONG — hardcoded port breaks on GCP:
    base_url="https://${host}:4985/${endpoint}"
    # CORRECT — use adminURL from the endpoint GET response:
    admin_url=$(echo "$get_resp" | jq -r '.adminURL // ""')
    curl -X POST "${admin_url}/_role/" -u "${ADMIN}:${PASS}" ...
    curl -X POST "${admin_url}/_user/" -u "${ADMIN}:${PASS}" ...
    ```
    The admin URL is also shown in: App Endpoint → Connect tab → "Connect for Admin REST" section.

24. **User setup flow — correct sequence:**
    1. Export `APPSVC_ADMIN_PASS='Passw0rd!'` (single quotes) before running the script
    2. Script creates the App Services Admin Credential via the Capella Management API (`POST .../appservices/{id}/adminUsers`) — no UI step needed
    3. Script sets up allowed CIDR `0.0.0.0/0` on the App Service, brings endpoint Online, then calls Admin REST API to create:
       - `admin` App Role — **created with `admin_channels: ["admin"]`** (Pattern A) so any user with this role inherits admin channel access
       - `manager` App User (`admin_roles: ["admin"]`, password = `MANAGER_PASS`) — inherits admin channel from the role
       - `bob` App User (regular, `admin_channels: ["bob"]`, password = `BOB_PASS`)
    4. Script prints WSS URL and next steps

25. **`admin_channels` must exactly match the username for regular App Users.** This seeds the per-user channel before the first document sync. Using any other value means documents won't be received even though authentication succeeds.

    **Admin channel access belongs on the ROLE, not the user.** Set `admin_channels` on the `admin` App Role — any user with `admin_roles: ["admin"]` inherits the channel automatically. Do NOT set `admin_channels` directly on admin App Users.

    **Generated `setup_app_users` function — always use this exact pattern:**
    ```bash
    setup_app_users() {
      local base_url="$1"   # adminURL from endpoint GET response

      # App Services with named scopes requires collection_access format — NOT flat admin_channels.
      # Flat admin_channels is silently ignored even when API returns 201/200.
      build_collection_access() {
        local channels_json="$1"
        local ca="{}"
        for pair in $COLLECTIONS; do
          local scope="${pair%%/*}" collection="${pair##*/}"
          ca=$(echo "$ca" | jq --arg s "$scope" --arg c "$collection" --argjson ch "$channels_json" \
            '.[$s][$c].admin_channels = $ch')
        done
        echo "$ca"
      }

      # ── Admin Role ──────────────────────────────────────────────────────────
      # collection_access on the ROLE grants channel to every user with this role.
      # ALWAYS PUT on 409 — POST-only silently skips update on re-run.
      log "   Creating/updating 'admin' App Role..."
      local admin_ca role_body
      admin_ca=$(build_collection_access '["admin"]')
      role_body=$(jq -n --arg name "admin" --argjson ca "$admin_ca" '{"name":$name,"collection_access":$ca}')
      local role_resp role_code
      role_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_role/" \
        -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
        -H "Content-Type: application/json" -d "$role_body") || true
      role_code=$(echo "$role_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
      if [[ "$role_code" == "409" ]]; then
        local put_code
        put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_role/admin" \
          -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
          -H "Content-Type: application/json" -d "$role_body") || true
        log "   ✅ App Role 'admin' updated (collection_access: admin) — HTTP $put_code"
      elif [[ "$role_code" == "201" ]]; then
        log "   ✅ App Role 'admin' created (collection_access: admin)"
      else
        log "   ⚠️  App Role POST returned HTTP $role_code"
      fi

      # ── Manager App User (admin role) ────────────────────────────────────────
      # admin_roles: ["admin"] — manager inherits collection_access from the role.
      # ALWAYS PUT on 409 to upsert.
      log "   Creating/updating '${MANAGER_USER}' App User..."
      local mgr_body
      mgr_body=$(jq -n --arg n "$MANAGER_USER" --arg p "$MANAGER_PASS" \
        '{"name":$n,"password":$p,"admin_roles":["admin"]}')
      local mgr_resp mgr_code
      mgr_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_user/" \
        -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
        -H "Content-Type: application/json" -d "$mgr_body") || true
      mgr_code=$(echo "$mgr_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
      if [[ "$mgr_code" == "409" ]]; then
        local mgr_put_code
        mgr_put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_user/${MANAGER_USER}" \
          -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
          -H "Content-Type: application/json" -d "$mgr_body") || true
        log "   ✅ App User '${MANAGER_USER}' updated (role: admin) — HTTP $mgr_put_code"
      elif [[ "$mgr_code" == "201" ]]; then
        log "   ✅ App User '${MANAGER_USER}' created (role: admin)"
      else
        log "   ⚠️  App User '${MANAGER_USER}' POST returned HTTP $mgr_code"
      fi

      # ── Regular App User ─────────────────────────────────────────────────────
      # collection_access channel MUST exactly match the username — personal sync channel.
      # ALWAYS PUT on 409 to upsert.
      log "   Creating/updating 'bob' App User..."
      local bob_ca bob_body
      bob_ca=$(build_collection_access '["bob"]')
      bob_body=$(jq -n --arg p "$BOB_PASS" --argjson ca "$bob_ca" \
        '{"name":"bob","password":$p,"collection_access":$ca}')
      local bob_resp bob_code
      bob_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_user/" \
        -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
        -H "Content-Type: application/json" -d "$bob_body") || true
      bob_code=$(echo "$bob_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
      if [[ "$bob_code" == "409" ]]; then
        local bob_put_code
        bob_put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_user/bob" \
          -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
          -H "Content-Type: application/json" -d "$bob_body") || true
        log "   ✅ App User 'bob' updated (channel: bob) — HTTP $bob_put_code"
      elif [[ "$bob_code" == "201" ]]; then
        log "   ✅ App User 'bob' created (channel: bob)"
      else
        log "   ⚠️  App User 'bob' POST returned HTTP $bob_code"
      fi
    }
    ```
    When generating a new script, use this `setup_app_users` function verbatim (adapting usernames/passwords to env vars). Never generate a script that only POSTs roles or users without the PUT-on-409 fallback.

26. **Handle free-tier cluster `turnedOff` state on re-run.** Free-tier clusters turn off after 72 hours of inactivity. When `get_or_create_cluster` finds a cluster with state `turnedOff`, POST to `/activationState` (cluster path) to wake it, then wait for healthy:
    ```bash
    if [[ "$existing_state" == "turnedOff" ]]; then
      api POST ".../clusters/freeTier/${cluster_id}/activationState" "" > /dev/null
    fi
    ```
    Note: cluster reactivation uses `/activationState`; App Endpoint bring-online uses `/activationStatus` — these are different paths for different resources.

27. **App Endpoint state lifecycle and correct ordering:**
    - States: `Initializing → Offline → Online`
    - After creation, poll until no longer `Initializing` (collections are being linked)
    - **Keep `Offline`** after initialization — this is the correct state while verifying the Access Control Function (Access Control Function is embedded at creation time, so review it before going live)
    - **Bring `Online` only when ready to accept connections** — this must happen BEFORE creating roles and users, because the Admin REST API requires the endpoint to be Online
    - Correct sequence: Create endpoint → wait for Offline → verify Access Control Function → bring Online → create roles and users

    ```bash
    # 1. Poll until out of Initializing
    while state == "Initializing": poll every 10s

    # 2. Keep Offline — Access Control Function is already embedded; verify it looks correct

    # 3. Bring Online (MUST happen before creating users)
    api POST ".../appEndpoints/${name}/activationStatus" "" > /dev/null

    # 4. Bring endpoint Online — use curl with || true, NOT api(). api() exits on 4xx.
    #    On re-runs the endpoint is already Online → activationStatus returns 4xx → api() kills the script
    #    before roles/users are updated. Always handle this non-fatally:
    activate_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      "${BASE_URL}${endpoints_path}/${CB_ENDPOINT_NAME}/activationStatus" \
      -H "Authorization: Bearer ${CB_API_KEY}" \
      -H "Content-Type: application/json") || true
    # 409/422 = already Online — that's fine. Only warn on unexpected codes.

    # 5. setup_app_users "$admin_url"
    #    Creates/upserts admin role (with admin_channels), manager user (admin_roles), bob user
    #    Uses POST→PUT-on-409 pattern — safe to re-run, always leaves correct config
    ```

