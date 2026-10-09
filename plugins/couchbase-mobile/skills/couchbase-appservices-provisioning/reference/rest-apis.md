## The three Couchbase REST surfaces — don't conflate them

Provisioning and running a Couchbase Mobile backend touches **different** REST APIs. Using the wrong one (or the wrong base URL/auth) is a common failure. There are three:

| API | Purpose | Base URL (shape) | Auth | Used by |
|---|---|---|---|---|
| **Capella Management API** (control plane) | Create/manage org resources: projects, clusters, buckets, scopes/collections, App Services, App Endpoints, allowed CIDRs, admin credentials | `https://cloudapi.cloud.couchbase.com/v4/...` | Capella API key (Organization Owner) | `setup-capella.sh` steps 1–11 |
| **App Services Admin REST API** (data-plane admin) | Create App **Roles** and App **Users**, set `admin_channels` / `collection_access` / `admin_roles`. **On Capella, this API has NO document read/write endpoints at all** (confirmed via the official Admin API reference) -- it is Session Management + Database Security only | the endpoint's **admin URL** (returned when the App Endpoint is created), port `4985`-style admin interface | App Services **Admin Credential** (created via the Management API) | `setup-capella.sh` step 12 (`/_role/`, `/_user/`) |
| **App Services Public REST API** (client-facing) | Per-document read/write and auth for end-user apps that talk HTTP instead of using Couchbase Lite. **This is also how CLAUDE seeds/writes documents itself** (see `SKILL.md`'s "Seed / test data") -- the Admin API cannot do it on Capella | the endpoint's **public URL** (`wss://…` for replication; `https://…` for REST) | App **User** credentials (e.g. `manager`, who holds the `admin` App Role) | Seed/verification writes (this skill); client-app replication uses CBL over WebSocket instead, not this REST surface directly |

### Why the distinction matters here

- **Roles, users, and channels are NOT created via the Management API.** They are created via the **Admin REST API** using the endpoint's admin URL and the Admin Credential. `setup-capella.sh` first uses the Management API to create the Admin Credential and open a CIDR (steps 10–11), *then* switches to the Admin REST API for roles/users (step 12). See `role-channel-rules.md` in the `couchbase-mobile-access-control-function` skill for the `/_role/` and `/_user/` bodies (including `collection_access`).
- **The Management API is spec-driven.** Always consult its OpenAPI spec before writing a call — see `management-api.md`. Content-Type and body shape vary by endpoint (e.g. `PUT /accessControlFunction` needs `application/javascript`).
- **The Public REST API is how documents get written on Capella, period -- there is no admin-level document write.** The cloud-edge iOS/Android app itself uses the Couchbase Lite replicator over WebSocket, not this REST surface, but *seed data and any other direct document write CLAUDE performs* must go through the Public API as an App User (see `SKILL.md`'s "Seed / test data" and `management-api.md` section 2 / `app-services-public-api.json`). Auth as the wrong kind of credential here isn't just unconventional, it fails outright: the Admin API returns no document endpoints on Capella, and `access()` never accepts the Admin Credential as a principal either way.

### Network reachability — a pure cloud session may not reach ports 4984/4985 at all

**Confirmed real case, both directions.** A cloud-only Claude session (no linked device) tried to call the Public REST API at `https://<host>.apps.cloud.couchbase.com:4984/...` and the connection opened, exchanged a few bytes, then dropped (abnormal close) after several seconds -- HTTPS on port 443 worked fine from the same session. This is the sandbox's own outbound egress proxy not carrying traffic on a non-standard port; it is **not** Capella refusing the connection (4984/4985 are normal public ports, nothing there is firewalled) and not a credentials or endpoint-URL problem, so don't debug it as either. Running the exact same `curl` from the user's own machine (a linked device, or the user's own terminal) worked immediately -- confirmed. So:

- **If a device bridge is linked, do Admin/Public REST API calls there**, not from the cloud workspace -- that traffic follows the user's own machine's network, which has no reason to share the sandbox's port restriction.
- **If no device is linked and a call to one of these two APIs hangs or drops without an HTTP error**, suspect this before anything else, say so plainly, and hand the user the exact command to run themselves (see `SKILL.md`'s "Seed / test data" for where the URL and credentials come from) rather than spending turns debugging the endpoint or the access control function.
- This applies to **both** non-Management-API surfaces in the table above (Admin REST *and* Public REST) -- the Management API itself (`cloudapi.cloud.couchbase.com`, port 443) is unaffected.

### Documentation

- Capella Management API reference: https://docs.couchbase.com/cloud/management-api-reference/index.html
- Management API OpenAPI spec (fetch on demand): https://docs.couchbase.com/cloud/management-api-reference/openapi.json
- App Services **Admin** REST API reference: https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html
- App Services **Public** REST API reference: https://docs.couchbase.com/app-services/references/rest_api_public.html
- App Services REST API overview (all three): https://docs.couchbase.com/cloud/app-services/references/rest-api-introduction.html
- Channels & access control: https://docs.couchbase.com/cloud/app-services/channels/channels.html
