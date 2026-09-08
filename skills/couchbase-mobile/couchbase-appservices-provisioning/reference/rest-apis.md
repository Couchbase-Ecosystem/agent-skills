## The three Couchbase REST surfaces — don't conflate them

Provisioning and running a Couchbase Mobile backend touches **different** REST APIs. Using the wrong one (or the wrong base URL/auth) is a common failure. There are three:

| API | Purpose | Base URL (shape) | Auth | Used by |
|---|---|---|---|---|
| **Capella Management API** (control plane) | Create/manage org resources: projects, clusters, buckets, scopes/collections, App Services, App Endpoints, allowed CIDRs, admin credentials | `https://cloudapi.cloud.couchbase.com/v4/...` | Capella API key (Organization Owner) | `setup-capella.sh` steps 1–11 |
| **App Services Admin REST API** (data-plane admin) | Create App **Roles** and App **Users**, set `admin_channels` / `collection_access` / `admin_roles`, inspect/manage the endpoint's sync data | the endpoint's **admin URL** (returned when the App Endpoint is created), port `4985`-style admin interface | App Services **Admin Credential** (created via the Management API) | `setup-capella.sh` step 12 (`/_role/`, `/_user/`) |
| **App Services Public REST API** (client-facing) | Per-document read/write and auth for end-user apps that talk HTTP instead of using Couchbase Lite | the endpoint's **public URL** (`wss://…` for replication; `https://…` for REST) | App **User** credentials | *Not this recipe.* The future `couchbase-rest-web-client` capability |

### Why the distinction matters here

- **Roles, users, and channels are NOT created via the Management API.** They are created via the **Admin REST API** using the endpoint's admin URL and the Admin Credential. `setup-capella.sh` first uses the Management API to create the Admin Credential and open a CIDR (steps 10–11), *then* switches to the Admin REST API for roles/users (step 12). See `role-channel-rules.md` in the `couchbase-mobile-access-control-function` skill for the `/_role/` and `/_user/` bodies (including `collection_access`).
- **The Management API is spec-driven.** Always consult its OpenAPI spec before writing a call — see `management-api.md`. Content-Type and body shape vary by endpoint (e.g. `PUT /accessControlFunction` needs `application/javascript`).
- **The Public REST API is out of scope for the cloud-edge iOS recipe** (the iOS app uses the Couchbase Lite replicator over WebSocket, not the Public REST API). It becomes relevant only for a REST/web client.

### Documentation

- Capella Management API reference: https://docs.couchbase.com/cloud/management-api-reference/index.html
- Management API OpenAPI spec (fetch on demand): https://docs.couchbase.com/cloud/management-api-reference/openapi.json
- App Services **Admin** REST API reference: https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html
- App Services **Public** REST API reference: https://docs.couchbase.com/app-services/references/rest_api_public.html
- App Services REST API overview (all three): https://docs.couchbase.com/cloud/app-services/references/rest-api-introduction.html
- Channels & access control: https://docs.couchbase.com/cloud/app-services/channels/channels.html
