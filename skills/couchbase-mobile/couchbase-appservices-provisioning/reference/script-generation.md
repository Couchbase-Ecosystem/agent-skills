## setup-capella.sh — Script Generation Rules (CRITICAL)

The goal is that the script **just works** on macOS on the first run. Every rule below was learned from a real failure. Do not deviate.

### ALWAYS read the OpenAPI spec before generating any API call

**Never assume Content-Type, body format, or path structure.** Every Capella Management API endpoint has specific requirements that differ from standard REST conventions. Before generating any `curl` or `api()` call:

1. **Check `content` in `requestBody`** — the key is the Content-Type (e.g. `application/json`, `application/javascript`, `text/plain`). Do NOT default to `application/json`.
2. **Check the `schema` under that content key** — `type: string` with `application/json` means a JSON-encoded string; `application/javascript` means raw JavaScript text; an object schema means a JSON object body.
3. **Check the response `content` type** — the GET response Content-Type tells you what format the PUT should send.
4. **Check path parameters** — some paths use UUIDs (`{clusterId}`), some use singleton literals (`freeTier`), some use compound keyspaces (`endpointName.scope.collection`).

**Real failures from not reading the spec:**
- `PUT /accessControlFunction` — Content-Type is `application/javascript`, body is raw JS text. Using `application/json` caused 400 "does not evaluate to a function".
- `POST /clusters/freeTier` — body requires `cloudProvider` with `type`+`region`+`cidr`. Sending just `{"name":"..."}` caused 422 "provider is not valid".
- `GET /clusters/freeTier/{clusterId}` — requires the UUID, not just the singleton path.
- `POST /appEndpoints` — returns 201 with **no body**; must GET separately to retrieve `publicURL` and `adminURL`.

**The OpenAPI spec is the source of truth.** The spec is publicly available — fetch it directly when generating API calls:

```bash
# Download the spec on demand (do not bundle with the skill)
curl -s "https://docs.couchbase.com/cloud/management-api-reference/openapi.json" -o /tmp/capella-spec.json

# Query any operation
python3 -c "
import json, sys
spec = json.load(open('/tmp/capella-spec.json'))
path = '/v4/organizations/{organizationId}/.../{resource}'
op = spec['paths'][path]['put']  # or post, get, delete
print('Request body:', json.dumps(op.get('requestBody',{}), indent=2))
print('Responses:', json.dumps(op.get('responses',{}), indent=2))
"
```

If the user has uploaded the spec JSON locally (e.g. `capella-management-api-spec.json`), use that. Otherwise fetch from the URL above. The spec covers all 169 API paths in the Capella Management API v4.0 and is the definitive reference — do not guess Content-Type or body format.

### bash correctness rules

1. **Never use `[[ condition ]] && command` or `(( expr )) && command`** with `set -e`. When the condition/expression is false, the whole `&&` expression returns 1 and `set -e` exits the script silently with no output. Always use `if/then`:
   ```bash
   # WRONG — silently kills the script when condition is false:
   [[ "$missing" == true ]] && exit 1
   (( elapsed >= MAX_WAIT )) && { log "timed out"; exit 1; }
   # CORRECT:
   if [[ "$missing" == true ]]; then exit 1; fi
   if (( elapsed >= MAX_WAIT )); then log "timed out"; exit 1; fi
   ```

2. **Arithmetic `(( var += n ))` returns exit 1 when result is 0** — triggers `set -e`. Always append `|| true`:
   ```bash
   (( elapsed += POLL_INTERVAL )) || true
   ```

3. **Never use `head -n -1`** — BSD `head` (macOS) rejects negative counts. Use `sed '$d'`:
   ```bash
   resp=$(echo "$raw" | sed '$d')   # removes last line, macOS+Linux safe
   ```

4. **Never use `declare -A`** — requires Bash 4+. macOS ships Bash 3.2. Use a space-separated string instead:
   ```bash
   # WRONG — fails on macOS system bash:
   declare -A seen=()
   seen[$key]=1
   [[ -z "${seen[$key]:-}" ]]
   # CORRECT — works everywhere:
   local seen=""
   seen+=" $key"
   [[ ! " $seen " =~ " $key " ]]
   ```

5. **All progress `echo` in functions called via `$(...)` must use `log()`**. Command substitution captures all stdout — progress lines go to stderr via `log()`, only the return value goes to stdout:
   ```bash
   log() { echo "$@" >&2; }
   # In every captured function: log "step N: doing X..."  (NOT echo)
   # Last line only: echo "$return_value"
   ```

6. **Never use `-f` in curl flags** — it silently suppresses the response body on 4xx/5xx, making errors invisible. Use `-s` only:
   ```bash
   args=(-s -X "$method" ...)   # NOT -sf
   ```

7. **Extract HTTP status code with a sentinel** — use `HTTPSTATUS:` prefix, `tr -d '\n'` before grep to handle multi-line responses, and strip stderr from the body:
   ```bash
   raw=$(curl "${args[@]}" -w "HTTPSTATUS:%{http_code}" 2>&1) || true
   http_code=$(echo "$raw" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
   resp=$(echo "$raw" | sed 's/HTTPSTATUS:[0-9]*$//')
   ```

8. **Guard every command substitution that returns an ID** — a subshell that exits on error returns empty, not an error. The parent never sees the error without an explicit check:
   ```bash
   cluster_id=$(create_cluster "$org_id" "$project_id")
   if [[ -z "$cluster_id" || "$cluster_id" == "null" ]]; then
     echo "❌ Cluster creation failed — check the error above." >&2; exit 1
   fi
   ```
   Do this for: project_id, cluster_id, app_service_id, public_url.

9. **Always add an ERR trap** immediately after `set -euo pipefail`:
   ```bash
   trap 'echo "❌ Failed at line $LINENO: $BASH_COMMAND" >&2' ERR
   ```

10. **Always `chmod +x` the script immediately after writing it.** Never make the user do it.

11. **Single quotes for all password exports** — double quotes expand `!` as bash history:
    ```bash
    export CB_API_KEY='your-key'   # single quotes always
    ```

