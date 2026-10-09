### App Endpoint name — must be meaningful

The App Endpoint is the **app's App Endpoint in the cloud** — it represents which app connects and what data it syncs. Name it after the app, not generically.

```bash
# WRONG — generic, meaningless:
export CB_ENDPOINT_NAME='mobile-endpoint'

# CORRECT — identifies the app:
export CB_ENDPOINT_NAME='todosync'         # Todo app
export CB_ENDPOINT_NAME='fieldtracker'     # Field inspection app
export CB_ENDPOINT_NAME='claims-app'       # Insurance claims app
```

Allowed characters: lowercase letters, numbers, `-`, `_`, `$`, `+`, `(`, `)`.

### Sync function files must match collection names in COLLECTIONS

The script looks for Access Control Functions at `sync-functions/<collection>-sync-function.js`. The collection name is the part after the `/` in the `COLLECTIONS` env var. These **must match** or the endpoint will use a passthrough default:

```bash
# COLLECTIONS='todo/todos' → requires: sync-functions/todos-sync-function.js
# COLLECTIONS='fieldops/tasks fieldops/resources' → requires:
#   sync-functions/tasks-sync-function.js
#   sync-functions/resources-sync-function.js
```

Always generate the correct Access Control Function files when generating the app. If a Access Control Function file is missing, the script warns and uses the passthrough default `function(doc,oldDoc){channel(doc.channels);}`.

### App Endpoint lifecycle — bring Online after creation

The App Endpoint is created in **Offline** state. The script must:
1. POST to create it (returns 201 with no body)
2. GET it to retrieve `publicURL` and `state`
3. If state is `Offline`, POST to `.../activationStatus` to bring it Online

```bash
# Create (no body returned):
api POST ".../appEndpoints" "$body" > /dev/null

# GET to retrieve publicURL + state:
get_resp=$(api GET ".../appEndpoints/${CB_ENDPOINT_NAME}")
public_url=$(echo "$get_resp" | jq -r '.publicURL // ""')
state=$(echo "$get_resp" | jq -r '.state // "unknown"')

# Bring Online if Offline:
if [[ "$state" == "Offline" ]]; then
  api POST ".../appEndpoints/${CB_ENDPOINT_NAME}/activationStatus" "" > /dev/null
fi
```

---

