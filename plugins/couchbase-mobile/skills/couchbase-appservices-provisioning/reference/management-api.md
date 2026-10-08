### 1. Capella Management API — OpenAPI spec (for ALL `setup-capella.sh` API calls)

**Use the bundled spec first: `reference/capella-management-api-v4.json`.** It's the real, full v4.0
spec (179 paths) — already on disk, no fetch needed. Read/grep it directly, e.g.:

```bash
python3 -c "
import json
d = json.load(open('reference/capella-management-api-v4.json'))
op = d['paths']['/v4/organizations/{organizationId}/projects/{projectId}/clusters']['get']
print(op['summary'], op['description'])
"
```

**Only fall back to a live fetch if the bundled file is missing or you suspect it's stale**
(Capella ships new API versions occasionally):

```bash
curl -s "https://docs.couchbase.com/cloud/management-api-reference/openapi.json" -o /tmp/capella-spec.json
```

Do **not** rely on `WebFetch` against the rendered HTML docs page
(`.../management-api-reference/index.html`) for endpoint paths or schemas — it's a
JS-rendered single-page app, and fetching it through a summarizing prompt has produced
plausible-looking but fabricated endpoint lists in practice (confirmed the hard way — see the
free-tier list/get note below). The raw OpenAPI JSON (bundled, or fetched from the URL above)
is the only reliable source.

Before generating **any** `curl` or `api()` call:
- Check `requestBody.content` — the key is the exact Content-Type to use (e.g. `application/json`, `application/javascript`, `text/plain`)
- Check the `schema` under that content key — `type: string` with `application/json` means a JSON-encoded string; an object schema means a JSON object body
- Check path parameters — some paths use UUIDs, some use singleton literals (`freeTier`), some use dot-separated keyspaces (`endpointName.scope.collection`)
- Check the response `content` type — GET response Content-Type tells you what format PUT must send

**Real failures from not checking the spec:**
- `PUT /accessControlFunction` needs `Content-Type: application/javascript` with raw JS — using `application/json` causes 400
- `POST /clusters/freeTier` requires `cloudProvider.cidr` even though the schema marks it optional — omitting causes 422
- `POST /appEndpoints` returns 201 with **no body** — must GET separately to get `publicURL` and `adminURL`
- **There is no collection-level "list free-tier X" endpoint for clusters or App Services** — only
  `GET .../clusters/freeTier/{clusterId}` and `GET .../appservices/freeTier/{appServiceId}` exist, both
  requiring an ID you don't have yet when checking whether one already exists. **Existence checks for
  clusters and App Services must use the general list** (`GET .../clusters`, which returns free-tier
  and paid clusters together — confirmed in the bundled spec's schema, nothing scopes it to paid-only).
  Buckets are the exception: `GET .../buckets/freeTier` is a real list endpoint. Getting this wrong
  once already shipped dead code that silently never found an existing free-tier cluster — see
  `free-tier-api.md` item 16.

### 2. App Services Public REST API -- OpenAPI spec (for document reads/writes, including seed data)

**Use the bundled spec first: `reference/app-services-public-api.json`.** It's the real Public
REST API spec (v4.0, Document/Session/Database Management/Attachment operations) -- already on
disk, no fetch needed. Read/grep it directly, e.g.:

```bash
python3 -c "
import json
d = json.load(open('reference/app-services-public-api.json'))
op = d['paths']['/{keyspace}/{docid}']['put']
print(op['summary'])
print(op['description'])
"
```

**Only fall back to a live fetch if the bundled file is missing or you suspect it's stale:**

```bash
curl -s "https://docs.couchbase.com/app-services/references/rest_api_public.html" ...
```
(that page is JS-rendered like the Management API docs -- prefer the bundled JSON; if you must
verify something not in it, ask the user rather than guessing from the rendered HTML.)

**This is a different surface from the Admin REST API** (section 1 above covers the Capella
Management API; `rest-apis.md` distinguishes all three). Key facts, confirmed from the bundled
spec and from the official Capella Admin API reference:

- **Capella's Admin REST API has no document endpoints at all.** It covers Session Management
  and Database Security (roles, users, channels, CORS) only -- `setup-capella.sh` step 12 uses it
  correctly for that. Never route a document read/write through it; on Capella it will not work
  (confirmed both by the official Admin API reference and empirically -- see `SKILL.md`'s
  "Seed / test data" section).
- **Documents go through the Public API**, base URL = the App Endpoint's `publicURL`
  (`https://{hostname}:4984`, already includes the endpoint/db name -- see `script-structure.md`
  item 31). The path parameter is a **keyspace**: `db`, `db.collection` (default scope), or
  `db.scope.collection` (fully qualified) -- use the fully-qualified form for a named
  scope/collection, matching `COLLECTIONS` in `provision.env`.
- **Two document-write operations** (see the spec's `Document` tag):
  - `POST /{keyspace}/` -- create with an App-Services-generated ID.
  - `PUT /{keyspace}/{docid}` -- upsert with an explicit ID (creates if absent, new revision if
    present; a `rev`/`If-Match` is required to update an *existing* doc -- omit it only for a
    brand-new ID).
- **Auth is HTTP Basic, as an App User -- not the Admin Credential.** The spec itself doesn't
  encode a security scheme (App Services enforces this via the endpoint's access control
  function/roles, not an API key), so any App User's credentials work for the transport; which
  *documents* that call is allowed to write is decided by the target keyspace's access control
  function via `requireRole()`/`channel()`. For a document that requires the `admin` App Role,
  authenticate as an App User holding that role -- in this skill's default setup, `MANAGER_USER`
  (default `manager`) / `MANAGER_PASS`, created in step 12 alongside `bob`. See
  `couchbase-mobile-access-control-function`'s `role-channel-rules.md` for exactly which role a
  given collection's ACF requires, and the "no `role:` prefix on App Services" rule when checking
  a role name.

**Real failure this corrected:** an earlier attempt tried writing seed documents via the Admin
REST API using `APPSVC_ADMIN_USER`/`APPSVC_ADMIN_PASS` -- Capella rejected it outright (Admin API
has no document path at all on Capella's hosted App Services, unlike self-managed Sync Gateway
where the admin port *does* expose data endpoints). Switching to the Public API as `manager`
combined with the `requireRole()` prefix fix (see `access-control-function` skill) is the
confirmed-correct combination.
