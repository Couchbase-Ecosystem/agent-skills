### 1. Capella Management API — OpenAPI spec (for ALL `setup-capella.sh` API calls)

```bash
curl -s "https://docs.couchbase.com/cloud/management-api-reference/openapi.json" -o /tmp/capella-spec.json
```

Before generating **any** `curl` or `api()` call:
- Check `requestBody.content` — the key is the exact Content-Type to use (e.g. `application/json`, `application/javascript`, `text/plain`)
- Check the `schema` under that content key — `type: string` with `application/json` means a JSON-encoded string; an object schema means a JSON object body
- Check path parameters — some paths use UUIDs, some use singleton literals (`freeTier`), some use dot-separated keyspaces (`endpointName.scope.collection`)
- Check the response `content` type — GET response Content-Type tells you what format PUT must send

**Real failures from not checking the spec:**
- `PUT /accessControlFunction` needs `Content-Type: application/javascript` with raw JS — using `application/json` causes 400
- `POST /clusters/freeTier` requires `cloudProvider.cidr` even though the schema marks it optional — omitting causes 422
- `POST /appEndpoints` returns 201 with **no body** — must GET separately to get `publicURL` and `adminURL`

