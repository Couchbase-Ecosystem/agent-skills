### Free-tier API rules

12. **Free-tier cluster creation — exact body (verified against live API):**
    - Required fields: `name`, `cloudProvider.type`, `cloudProvider.region`, `cloudProvider.cidr`
    - `cidr` is marked optional in the OpenAPI schema but the API enforces it — omitting it causes 422 "CIDR provided with value, , is not valid"
    - Valid `cloudProvider.type`: `"aws"`, `"gcp"`, `"azure"`
    - Valid cidr: any private IPv4 range /16–/25 (e.g. `10.0.64.0/23`)

    ```bash
    # WRONG — missing cidr (422 "CIDR provided with value, , is not valid"):
    body='{"name":"x","cloudProvider":{"type":"aws","region":"us-east-2"}}'
    # WRONG — missing cloudProvider entirely (422: "provider is not valid"):
    body='{"name":"x"}'
    # CORRECT:
    body=$(jq -n --arg n "$CB_CLUSTER_NAME" --arg p "$CLOUD_PROVIDER" \
                 --arg r "$CLOUD_REGION"    --arg c "$CLOUD_CIDR" \
      '{"name":$n,"cloudProvider":{"type":$p,"region":$r,"cidr":$c}}')
    ```
    Default env vars — keep it simple, user only overrides if they get a conflict:
    ```bash
    CLOUD_PROVIDER="${CLOUD_PROVIDER:-aws}"
    CLOUD_REGION="${CLOUD_REGION:-us-east-2}"
    CLOUD_CIDR="${CLOUD_CIDR:-10.0.64.0/23}"   # change if you get a CIDR conflict error
    ```

13. **Free-tier App Service body — `name` only** (no `clusterId` in body — cluster is identified by path):
    ```bash
    body=$(jq -n --arg n "$CB_APP_SERVICE_NAME" '{"name":$n}')
    ```

14. **Free-tier Bucket body — `name` only** (optional: `memoryAllocationInMb`, default 100 MiB):
    ```bash
    body=$(jq -n --arg n "$CB_BUCKET_NAME" '{"name":$n}')
    ```
    **Always capture and return the bucket UUID from the create/list response.** The scopes and collections API paths require the bucket UUID, not the bucket name. Using the name causes a 404 "bucket does not exist" error:
    ```bash
    # WRONG — uses bucket name in path:
    base=".../buckets/${CB_BUCKET_NAME}/scopes"
    # CORRECT — uses bucket UUID from API response:
    bucket_id=$(echo "$resp" | jq -r '.id')
    base=".../buckets/${bucket_id}/scopes"
    ```

15. **Never use `_default` scope for collections.** See Data Modeling in `couchbase-mobile-concepts-patterns`. Always use a named scope. The script must:
    - Default COLLECTIONS to a named scope (not `_default/tasks _default/resources`)
    - Skip any `_default/xxx` pair with a warning instead of attempting to create it
    - The iOS app's `AppConfig.swift` `scopeName` must match the named scope used in COLLECTIONS
    - CBL queries must reference the named scope: `FROM scopeName.collectionName`

16. **Free-tier API paths — use exactly these** (verified against the bundled OpenAPI spec,
    `reference/capella-management-api-v4.json` — the authoritative source; re-check there before
    trusting anything below if Capella ships a new API version):

    | Operation | Method | Path |
    |-----------|--------|------|
    | **List clusters (paid + free-tier together)** | GET | `/clusters` — **the only way to check whether a free-tier cluster already exists; see the asymmetry note below** |
    | Create free-tier cluster | POST | `/clusters/freeTier` |
    | Get/poll free-tier cluster | GET | `/clusters/freeTier/{clusterId}` — **requires a known ID; not a list** |
    | Create free-tier bucket | POST | `/clusters/{clusterId}/buckets/freeTier` — body: `{"name":"..."}` |
    | List free-tier buckets | GET | `/clusters/{clusterId}/buckets/freeTier` |
    | Create scope | POST | `/clusters/{clusterId}/buckets/{bucketId}/scopes` — **bucketId = UUID, NOT name** |
    | Create collection | POST | `/clusters/{clusterId}/buckets/{bucketId}/scopes/{scope}/collections` |
    | List App Services (org-wide) | GET | `/organizations/{organizationId}/appservices` — filter client-side by `clusterId`; there's no project/cluster-scoped list |
    | Create free-tier App Service | POST | `/clusters/{clusterId}/appservices/freeTier` — body: `{"name":"..."}` |
    | Get/poll free-tier App Service | GET | `/clusters/{clusterId}/appservices/freeTier/{appServiceId}` — **requires a known ID; not a list** |
    | Create App Endpoint | POST | `/clusters/{clusterId}/appservices/{appServiceId}/appEndpoints` |
    | Get App Endpoint | GET | `/clusters/{clusterId}/appservices/{appServiceId}/appEndpoints/{endpointName}` |
    | Bring endpoint Online | POST | `/clusters/{clusterId}/appservices/{appServiceId}/appEndpoints/{endpointName}/activationStatus` |

    **Critical notes on these paths:**
    - Scopes/collections use **bucket UUID** (from create/list response), NOT the bucket name — using the name returns 404
    - App Endpoint POST returns 201 with **no body** — must GET after creation to retrieve `publicURL` and `state`
    - App Endpoint starts in **Offline** state — must POST to `/activationStatus` to bring it Online
    - **List vs. Get asymmetry — easy to get wrong.** Buckets have a real free-tier *list* endpoint
      (`GET .../buckets/freeTier`). Clusters and App Services do **not** — their `freeTier` GET always
      takes an ID (`{clusterId}` / `{appServiceId}`), so it can only fetch a resource you already know
      about, never discover one. To check "does a free-tier cluster/App Service already exist in this
      project", you **must** call the general list (`GET .../clusters`, `GET .../organizations/{id}/appservices`)
      and inspect the results — there is no free-tier-scoped shortcut. Do not invent one (a real attempt
      to query a nonexistent `GET .../clusters/freeTier` with no ID silently returned nothing every time
      and shipped as dead code for a few hours before being caught against the real spec).

17. **App Endpoint name must be meaningful and app-specific.** It represents the app's App Endpoint in the cloud. Bad: `mobile-endpoint`. Good: `todosync`, `fieldtracker`, `claims-app`.
    - Allowed chars: lowercase letters, numbers, `-`, `_`, `$`, `+`, `(`, `)`
    - Set via `CB_ENDPOINT_NAME` env var — always document this with an app-specific example

18. **Access Control Function file names must match collection names, and `SYNC_FUNCTIONS_DIR` must point to the right location.**
    The script looks for `${SYNC_FUNCTIONS_DIR}/<collection>-sync-function.js` (file naming convention) where `<collection>` is the part after `/` in `COLLECTIONS`:
    ```
    COLLECTIONS='todo/todos'             → ${SYNC_FUNCTIONS_DIR}/todos-sync-function.js
    COLLECTIONS='fieldops/tasks'         → ${SYNC_FUNCTIONS_DIR}/tasks-sync-function.js
    COLLECTIONS='claims/submissions'     → ${SYNC_FUNCTIONS_DIR}/submissions-sync-function.js
    ```

    `SYNC_FUNCTIONS_DIR` defaults to `sync-functions/` next to the script. **Always tell the user to set it** if their app's Access Control Functions are in a subfolder:
    ```bash
    export SYNC_FUNCTIONS_DIR='sync-functions'           # resolved relative to setup-capella.sh; no project-name prefix
    # OR run from inside the app folder:
    cd TodoSync && ../setup-capella.sh
    ```

    If an Access Control Function file is missing, the script warns and uses a **passthrough default** (`function(doc,oldDoc){channel(doc.channels);}`). This is NOT a correct Access Control Function — the App Endpoint will be insecure. Always generate the correct Access Control Function file for each collection and verify it was embedded correctly.

    Always generate the correct Access Control Function files when generating the app — one per collection.

19. **Only 1 free-tier cluster is allowed per organization** (confirmed on Couchbase's own docs: *"Only 1 free tier operational cluster is available per organization"*, and confirmed live: a target project with zero clusters — `"totalItems":0"` in the API's own response — still 422'd on `POST /clusters/freeTier` with `"Self service trials are limited to provisioning one cluster"` because the org's one cluster was in a different project). A 2nd `POST /clusters/freeTier` in the same org fails with 422. `setup-capella.sh` guards against this with `find_org_freetier_cluster`, which scans **every project in the org** before creating anything — not just the target project, and not by name (confirmed necessary: the same org can have multiple projects sharing the exact same name, with the real cluster sitting in a different duplicate than a name lookup would pick). If a match is found elsewhere, it asks whether to redirect into that existing project/cluster or stop, instead of creating a doomed 2nd cluster and leaving an orphaned empty project behind -- but only when this app's own bucket isn't already sitting in that cluster from a prior run; if it is, nothing new would be created, so it reuses silently instead of re-asking every time. See `backend-setup.md` for the user-facing warning and `script-structure.md` for how the check works.

