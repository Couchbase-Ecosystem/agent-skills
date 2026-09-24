#!/usr/bin/env bash
# =============================================================================
# setup-capella.sh — Idempotent Capella backend setup for Couchbase Mobile
#
# SAFE TO RE-RUN: checks if each resource already exists before creating it.
#
# What this script does (in order):
#   1.  Resolves your org ID
#   2.  Finds or creates a Capella project
#   3.  Finds or creates a free-tier cluster; turns it on if turned off
#   4.  Waits for cluster to become healthy (5–25 min first run)
#   5.  Finds or creates the bucket (returns UUID — required for scopes API)
#   6.  Finds or creates scopes + collections (skips _default, skips existing)
#   7.  Finds or creates an App Service
#   8.  Waits for App Service to become healthy (15–25 min first run)
#   9.  Finds or creates an App Endpoint with Access Control Function embedded
#   9b. Always updates the Access Control Function (runs even on re-run)
#   10. Creates App Services Admin Credential via Capella Management API
#   11. Adds 0.0.0.0/0 allowed CIDR (required to reach Admin REST API)
#   12. Creates App Role 'admin' + App Users via Admin REST API
#
# Prerequisites:
#   brew install jq
#   Capella API key with Organization Owner role:
#     Capella UI → select your Organization → Settings → API Keys → Generate Key (Organization Owner)
#
# Usage:
#   export CB_API_KEY='your-api-key-secret'
#   ./setup-capella.sh
#   # APPSVC_ADMIN_PASS is optional — leave it unset and the script generates a strong one
#   # and saves it to provision.env (never printed anywhere). Set your own (single-quoted,
#   # to avoid bash expanding !) if you'd rather choose it.
#   # MANAGER_PASS / BOB_PASS are optional too, and default to 'Password1!' if left unset —
#   # fine for these, they're low-privilege test accounts you type into the app.
#
#   If you're using provision.env (recommended — see provision.env.example), set these
#   values directly IN THAT FILE, not via `export` in your shell first: `source
#   provision.env` runs before this script and will overwrite a same-named shell export
#   with the file's own value (blank, by default).
#
# Optional overrides (defaults work for most users):
#   export CLOUD_PROVIDER='aws'           # aws (default), gcp, azure
#   export CLOUD_REGION='us-east-2'
#   export CLOUD_CIDR='10.0.64.0/23'     # change only on CIDR conflict
#   export CB_PROJECT_NAME='MyProject'
#   export CB_CLUSTER_NAME='my-cluster'
#   export CB_BUCKET_NAME='myapp'
#   export CB_APP_SERVICE_NAME='my-app-service'
#   export CB_ENDPOINT_NAME='todosync'    # app-specific, e.g. todosync, fieldtracker
#   export COLLECTIONS='todo/todos'       # space-separated scope/collection pairs
#   export SYNC_FUNCTIONS_DIR='sync-functions'   # relative to THIS script's location (no project-name prefix)
# =============================================================================

set -euo pipefail
trap 'echo "" >&2; echo "❌ Script failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# --- Dependency preflight: this script needs jq and curl ---
for _dep in jq curl; do
  if ! command -v "$_dep" >/dev/null 2>&1; then
    echo "❌ Required tool '$_dep' is not installed or not on PATH." >&2
    echo "   Install it, then re-run this script:" >&2
    echo "     macOS:  brew install $_dep" >&2
    echo "     Linux:  sudo apt-get install -y $_dep   # or your distro's package manager" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------

CB_API_KEY="${CB_API_KEY:-}"

# Resolved once, used to find provision.env so a generated Admin Credential password can be
# saved back into it (see _persist_secret below) — works no matter what directory this is
# run from, and is reused later to resolve SYNC_FUNCTIONS_DIR.
_script_dir="$(cd "$(dirname "$0")" && pwd)"
_provision_env_file="${_script_dir}/provision.env"

# Generates a password meeting the Admin/App User complexity rule (8+ chars: upper, lower,
# digit, special) using only bash builtins — no subprocess/pipe, so there's nothing for a
# shell-output leak to expose the way a printed credential could be.
_generate_password() {
  local len="${1:-20}" i r tmp out=""
  local upper='ABCDEFGHJKLMNPQRSTUVWXYZ'   # no ambiguous I/O
  local lower='abcdefghijkmnpqrstuvwxyz'   # no ambiguous l/o
  local digit='23456789'                   # no ambiguous 0/1
  local special='!@+'   # Narrowed to only chars with POSITIVE confirmed-safe evidence from live Capella API testing.
  # Capella publishes no allowed/disallowed character list for Admin Credential passwords. Confirmed REJECTED
  # empirically (HTTP 422): '=' and '&' -- both are form/URL-encoding delimiter characters, so #%^*_ were
  # dropped too rather than risk another round of guess-and-check. Confirmed ACCEPTED: '!' '@' '+'.
  local all="${upper}${lower}${digit}${special}"
  local -a chars=(
    "${upper:$((RANDOM % ${#upper})):1}"
    "${lower:$((RANDOM % ${#lower})):1}"
    "${digit:$((RANDOM % ${#digit})):1}"
    "${special:$((RANDOM % ${#special})):1}"
  )
  for (( i = 4; i < len; i++ )); do
    chars+=("${all:$((RANDOM % ${#all})):1}")
  done
  for (( i = ${#chars[@]} - 1; i > 0; i-- )); do
    r=$(( RANDOM % (i + 1) ))
    tmp="${chars[i]}"; chars[i]="${chars[r]}"; chars[r]="$tmp"
  done
  for (( i = 0; i < ${#chars[@]}; i++ )); do out+="${chars[i]}"; done
  printf '%s' "$out"
}

# Saves a generated secret back into provision.env so it survives re-runs. Without this, a
# value generated here would only live in this one invocation — and since Step 10 always
# deletes and recreates the Admin Credential to match APPSVC_ADMIN_PASS (its password can't
# be read back or updated via the API), the password would silently change on every re-run.
# Only ever touches the one line for the given var.
_persist_secret() {
  local var="$1" val="$2"
  if [[ ! -f "$_provision_env_file" ]]; then
    echo "   ⚠️  provision.env not found next to the script — generated ${var} applies to this run only." >&2
    return 0
  fi
  # Pure-bash line rewrite (no sed/awk) — the generated value can contain regex-special
  # characters (#, &, ^, *, ...) that would corrupt a sed s/// pattern or replacement.
  local line found=0
  local -a out=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "export ${var}="* ]]; then
      out+=("export ${var}='${val}'")
      found=1
    else
      out+=("$line")
    fi
  done < "$_provision_env_file"
  if [[ "$found" -eq 0 ]]; then
    out+=("export ${var}='${val}'")
  fi
  printf '%s\n' "${out[@]}" > "$_provision_env_file"
}

# App Services Admin Credential — used to create and manage App Users and App Roles.
# To use your own, put it directly on the APPSVC_ADMIN_PASS line in provision.env before
# running (must meet: min 8 chars, uppercase + lowercase + number + special char; AVOID '=' and
# '&' -- Capella's Admin Credential API rejects both with HTTP 422, confirmed empirically; stick
# to '!' '@' '+' as specials if unsure). Don't
# `export` it in your shell instead — `source provision.env` runs first, and its blank
# `export APPSVC_ADMIN_PASS=''` line will overwrite that shell export with nothing. Leave it
# blank in the file (recommended) and the script generates a strong one and saves it back to
# provision.env — it is never printed anywhere, including here.
APPSVC_ADMIN_USER="${APPSVC_ADMIN_USER:-admin}"
if [[ -z "${APPSVC_ADMIN_PASS:-}" ]]; then
  APPSVC_ADMIN_PASS="$(_generate_password 20)"
  _persist_secret APPSVC_ADMIN_PASS "$APPSVC_ADMIN_PASS"
  echo "🔑 Generated APPSVC_ADMIN_PASS and saved it to provision.env (never printed)."
fi

# App Users created by the script.
# "manager" = admin App Role — sees all docs, creates and assigns tasks.
# "bob"     = regular App User — sees only their own assigned docs.
# To use your own MANAGER_PASS / BOB_PASS, put them directly in provision.env the same way
# (same reason as above — not as a shell export). Left blank, both default to 'Password1!' —
# fine for these, they're low-privilege test accounts you'll type into the app to sign in.
MANAGER_USER="${MANAGER_USER:-manager}"
MANAGER_PASS="${MANAGER_PASS:-Password1!}"
BOB_PASS="${BOB_PASS:-Password1!}"

CB_PROJECT_NAME="${CB_PROJECT_NAME:-MobileDevProject}"
CB_CLUSTER_NAME="${CB_CLUSTER_NAME:-mobile-dev-cluster}"
CB_BUCKET_NAME="${CB_BUCKET_NAME:-mobileapp}"
CB_APP_SERVICE_NAME="${CB_APP_SERVICE_NAME:-mobile-app-service}"
CB_ENDPOINT_NAME="${CB_ENDPOINT_NAME:-mobile-app}"

CLOUD_PROVIDER="${CLOUD_PROVIDER:-aws}"
CLOUD_REGION="${CLOUD_REGION:-us-east-2}"
# Valid: any private IPv4 range /16–/25. Change only if you get a CIDR conflict.
CLOUD_CIDR="${CLOUD_CIDR:-10.0.64.0/23}"

# Space-separated scope/collection pairs — always use a named scope, never _default.
# Script looks for: ${SYNC_FUNCTIONS_DIR}/<collection>-sync-function.js
#   export COLLECTIONS='todo/todos'                         # TodoSync
#   export COLLECTIONS='fieldops/tasks fieldops/resources'  # multi-collection
COLLECTIONS="${COLLECTIONS:-todo/todos}"

# Access Control Function directory.
# IMPORTANT: SYNC_FUNCTIONS_DIR is resolved relative to THIS SCRIPT's location, not your
# current working directory — so it works no matter where you run the script from, and a
# project-name prefix in the value won't double up (e.g. running inside RetailPOSApp/ with
# SYNC_FUNCTIONS_DIR='RetailPOSApp/sync-functions' still resolves correctly).
# Resolution order: env var (as-is → relative to script dir → by basename under script dir)
#   → sync-functions/ next to the script → first sync-functions/ found under the script dir.
_resolve_sfd() {
  local v="$1"
  [[ -d "$v" ]] && { (cd "$v" && pwd); return; }                                  # absolute, or relative to CWD
  [[ -d "${_script_dir}/${v}" ]] && { echo "${_script_dir}/${v}"; return; }        # relative to the script dir
  [[ -d "${_script_dir}/${v##*/}" ]] && { echo "${_script_dir}/${v##*/}"; return; } # just the folder name, under script dir
  echo ""
}
if [[ -n "${SYNC_FUNCTIONS_DIR:-}" ]]; then
  _r="$(_resolve_sfd "$SYNC_FUNCTIONS_DIR")"
  if [[ -n "$_r" ]]; then
    SYNC_FUNCTIONS_DIR="$_r"
  fi   # else leave as set — the per-collection existence check will report the exact missing path
elif [[ -d "${_script_dir}/sync-functions" ]]; then
  SYNC_FUNCTIONS_DIR="${_script_dir}/sync-functions"
else
  _found=$(find "$_script_dir" -maxdepth 2 -type d -name "sync-functions" 2>/dev/null | head -1)
  SYNC_FUNCTIONS_DIR="${_found:-${_script_dir}/sync-functions}"
fi

FREE_TIER="${FREE_TIER:-true}"

# ---------------------------------------------------------------------------
# INTERNALS
# ---------------------------------------------------------------------------

BASE_URL="https://cloudapi.cloud.couchbase.com/v4"
POLL_INTERVAL=20
MAX_WAIT=1800

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

log() { echo "$@" >&2; }

check_deps() {
  for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ '$cmd' is required. Install with: brew install $cmd"
      exit 1
    fi
  done
}

validate_config() {
  if [[ -z "$CB_API_KEY" ]]; then
    echo "❌ CB_API_KEY is not set."
    echo "   Generate a key with Organization Owner role in:"
    echo "   Capella UI → select your Organization → Settings → API Keys → Generate Key (Organization Owner)"
    echo "   Then: export CB_API_KEY='your-secret'"
    exit 1
  fi
}

# Authenticated Capella Management API call — exits on HTTP 4xx/5xx.
# All progress output uses log() → stderr. Only return values go to stdout.
api() {
  local method="$1" path="$2" body="${3:-}"
  local args=(-s -X "$method" "${BASE_URL}${path}" \
    -H "Authorization: Bearer ${CB_API_KEY}" \
    -H "Accept: application/json")
  if [[ -n "$body" ]]; then
    args+=(-H "Content-Type: application/json" -d "$body")
  fi
  local raw http_code resp
  raw=$(curl "${args[@]}" -w "HTTPSTATUS:%{http_code}" 2>&1) || true
  http_code=$(echo "$raw" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
  resp=$(echo "$raw" | sed 's/HTTPSTATUS:[0-9]*$//')
  if [[ -z "$http_code" ]]; then
    log "❌ curl failed for $method $path"; log "   raw: $raw"; exit 1
  fi
  if [[ "$http_code" -ge 400 ]]; then
    log "❌ API error ($method $path) HTTP $http_code"
    log "   Body: $resp"
    exit 1
  fi
  echo "$resp"
}

# Like api() but returns empty string on 4xx instead of exiting.
# Use for existence checks where "not found" is a valid outcome.
api_or_empty() {
  local method="$1" path="$2" body="${3:-}"
  local args=(-s -X "$method" "${BASE_URL}${path}" \
    -H "Authorization: Bearer ${CB_API_KEY}" \
    -H "Accept: application/json")
  if [[ -n "$body" ]]; then
    args+=(-H "Content-Type: application/json" -d "$body")
  fi
  local raw http_code resp
  raw=$(curl "${args[@]}" -w "HTTPSTATUS:%{http_code}" 2>&1) || true
  http_code=$(echo "$raw" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
  resp=$(echo "$raw" | sed 's/HTTPSTATUS:[0-9]*$//')
  if [[ -z "$http_code" || "$http_code" -ge 400 ]]; then
    echo ""
    return 0
  fi
  echo "$resp"
}

# Poll a GET path until jq_expr equals target. Returns final response on stdout.
wait_for_state() {
  local label="$1" path="$2" target="$3" jq_expr="${4:-.currentState}"
  log ""
  log "⏳ Waiting for $label to become '$target'..."
  log "   (Free-tier provisioning: 5–25 min. Please be patient.)"
  local elapsed=0
  while true; do
    local resp state
    resp=$(api GET "$path") || true
    state=$(echo "$resp" | jq -r "$jq_expr" 2>/dev/null || echo "unknown")
    printf "   [%3ds] state: %s\n" "$elapsed" "$state" >&2
    if [[ "$state" == "$target" ]]; then
      log "   ✅ $label is $target."
      echo "$resp"
      return 0
    fi
    if (( elapsed >= MAX_WAIT )); then
      log "❌ Timed out after ${MAX_WAIT}s waiting for $label."
      exit 1
    fi
    sleep "$POLL_INTERVAL"
    (( elapsed += POLL_INTERVAL )) || true
  done
}

# ---------------------------------------------------------------------------
# STEP 1 — Org ID
# ---------------------------------------------------------------------------

get_org_id() {
  log ""
  log "🔍 Step 1: Resolving organization..."
  local resp org_id
  resp=$(api GET "/organizations")
  org_id=$(echo "$resp" | jq -r '.data[0].id')
  if [[ -z "$org_id" || "$org_id" == "null" ]]; then
    log "❌ Could not resolve org ID. Check your API key."; exit 1
  fi
  log "   Org ID: $org_id"
  echo "$org_id"
}

# ---------------------------------------------------------------------------
# STEP 2 — Project (idempotent)
# ---------------------------------------------------------------------------

get_or_create_project() {
  local org_id="$1"
  log ""
  log "📁 Step 2: Finding or creating project '$CB_PROJECT_NAME'..."

  local list_resp
  list_resp=$(api GET "/organizations/${org_id}/projects")

  # The same org can have MULTIPLE projects sharing the exact same name (confirmed on a
  # real account). Blindly reusing the first name-match can land in an empty duplicate
  # while a different, same-named duplicate holds this app's actual cluster. For a paid
  # (non-free-tier) cluster that doesn't fail loudly like the free-tier case does -- it
  # silently provisions a second cluster in the wrong duplicate and starts billing for it.
  # So when more than one project shares the name, check each candidate for the target
  # cluster first and prefer whichever one actually has it, instead of guessing.
  local name_matches match_count
  name_matches=$(echo "$list_resp" | jq -r --arg n "$CB_PROJECT_NAME" \
    '.data[]? | select(.name == $n) | .id')
  match_count=$(printf '%s\n' "$name_matches" | grep -c . || true)

  if [[ "$match_count" -gt 1 ]]; then
    log "   ⚠️  Found $match_count projects named '$CB_PROJECT_NAME' -- checking which one has cluster '$CB_CLUSTER_NAME'..."
    local dup_pid dup_clist dup_crows dup_cid
    while IFS= read -r dup_pid; do
      [[ -z "$dup_pid" ]] && continue
      dup_clist=$(api_or_empty GET "/organizations/${org_id}/projects/${dup_pid}/clusters")
      dup_crows=$(_cluster_rows "$dup_clist")
      dup_cid=$(printf '%s\n' "$dup_crows" | awk -F'\t' -v n="$CB_CLUSTER_NAME" '$2==n{print $1; exit}')
      if [[ -n "$dup_cid" ]]; then
        log "   ♻️  Project '$CB_PROJECT_NAME' ($dup_pid) has cluster '$CB_CLUSTER_NAME' -- using this one."
        echo "$dup_pid"
        return
      fi
    done <<< "$name_matches"
    log "   None of the $match_count duplicates has cluster '$CB_CLUSTER_NAME' yet -- using the first found."
  fi

  local existing_id
  existing_id=$(printf '%s\n' "$name_matches" | head -1)

  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    log "   ♻️  Reusing existing project: $existing_id"
    echo "$existing_id"
    return
  fi

  # Target project doesn't exist yet. If the org already has OTHER projects,
  # confirm before creating a new one -- Capella allows only 1 free-tier
  # cluster per org, so an existing project may already hold it. Surfacing
  # the existing names here is what lets the user avoid a doomed 2nd cluster.
  local other_names other_count
  other_names=$(echo "$list_resp" | jq -r '.data[]?.name // empty')
  other_count=$(printf '%s\n' "$other_names" | grep -c . || true)

  if [[ "$other_count" -gt 0 ]]; then
    log ""
    log "   ⚠️  This organization already has $other_count project(s):"
    while IFS= read -r n; do [[ -n "$n" ]] && log "      - $n"; done <<< "$other_names"
    log ""
    read -r -p "   OK to create a NEW project named '$CB_PROJECT_NAME'? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      log ""
      read -r -p "   Which existing project should I use instead? (enter the name exactly, or press Enter to cancel): " chosen
      if [[ -z "$chosen" ]]; then
        log ""
        log "❌ Cancelled -- nothing was created."
        exit 1
      fi
      local chosen_id
      chosen_id=$(echo "$list_resp" | jq -r --arg n "$chosen" '.data[]? | select(.name == $n) | .id' | head -1)
      if [[ -z "$chosen_id" || "$chosen_id" == "null" ]]; then
        log ""
        log "❌ '$chosen' doesn't match any existing project. Existing projects:"
        while IFS= read -r n; do [[ -n "$n" ]] && log "      - $n"; done <<< "$other_names"
        log "   Re-run and enter one of these exactly."
        exit 1
      fi
      log "   ♻️  Using existing project '$chosen': $chosen_id"
      echo "$chosen_id"
      return
    fi
  fi

  local resp id
  resp=$(api POST "/organizations/${org_id}/projects" \
    "$(jq -n --arg n "$CB_PROJECT_NAME" \
      '{"name":$n,"description":"Auto-created by setup-capella.sh"}')")
  id=$(echo "$resp" | jq -r '.id')
  log "   ✅ Project created: $id"
  echo "$id"
}

# ---------------------------------------------------------------------------
# STEP 3 — Cluster (idempotent, handles turnedOff state)
# ---------------------------------------------------------------------------

# Extracts "<id>\t<name>\t<currentState>" lines from a Capella "list clusters" response
# ({"data":[...]}) -- defensively also accepts a bare list or a single bare object, in case
# this is ever reused against a different endpoint shape.
_cluster_rows() {
  local resp="$1"
  [[ -z "$resp" ]] && return 0
  echo "$resp" | jq -r '
    def rows: if (type) == "array" then .[]
      elif (type) == "object" and has("data") then (.data // [])[]
      elif (type) == "object" and has("id") then .
      else empty end;
    rows | [(.id // empty), (.name // empty), (.currentState // empty)] | @tsv
  ' 2>/dev/null
}

get_or_create_cluster() {
  local org_id="$1" project_id="$2"
  log ""
  log "☁️  Step 3: Finding or creating cluster '$CB_CLUSTER_NAME'..."

  # Verified against the Capella v4 Management API spec (bundled in this skill's
  # reference/ -- see references/capella-management-api-v4.json): there is NO
  # collection-level "list free-tier clusters" endpoint. GET .../clusters/freeTier requires
  # a clusterId (it's a "get one", not "list"); listing -- free-tier or otherwise -- goes
  # only through the general GET .../clusters, which is the complete, correct source for
  # this check. (A dead code path that queried .../clusters/freeTier with no ID was removed
  # here -- that endpoint does not exist and always returned nothing.)
  local list_resp rows existing_id existing_state
  list_resp=$(api GET "/organizations/${org_id}/projects/${project_id}/clusters")
  rows="$(_cluster_rows "$list_resp")"

  # Always log what the list call actually returned -- this has disagreed with the documented
  # API behavior in practice (a real free-tier cluster in the target project went undetected
  # once already), so leave this visible rather than only logging on the happy path.
  if [[ -z "$rows" ]]; then
    log "   (debug) clusters list for this project came back empty. Raw response: $list_resp"
  else
    log "   (debug) clusters found in this project:"
    while IFS=$'\t' read -r _rid _rname _rstate; do
      [[ -n "$_rid" ]] && log "   (debug)   - '$_rname' ($_rid) state=$_rstate"
    done <<< "$rows"
  fi

  existing_id=$(printf '%s\n' "$rows" | awk -F'\t' -v n="$CB_CLUSTER_NAME" '$2==n{print $1; exit}')

  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    existing_state=$(printf '%s\n' "$rows" | awk -F'\t' -v n="$CB_CLUSTER_NAME" '$2==n{print $3; exit}')
    log "   ♻️  Found existing cluster (state: $existing_state): $existing_id"
    # Free-tier clusters turn off after 72h inactivity — wake it up
    if [[ "$existing_state" == "turnedOff" ]]; then
      log "   Cluster is off — turning it on..."
      api POST "/organizations/${org_id}/projects/${project_id}/clusters/freeTier/${existing_id}/activationState" "" > /dev/null
      log "   Cluster wake requested. Waiting for healthy..."
    fi
    echo "$existing_id"
    return
  fi

  # No cluster named $CB_CLUSTER_NAME, but this project may already hold a
  # DIFFERENT cluster. Capella allows only 1 free-tier cluster per org, so
  # attempting to create a 2nd one here would 422 -- ask first.
  local any_id any_name any_state
  any_id=$(printf '%s\n' "$rows" | awk -F'\t' '$1!=""{print $1; exit}')
  if [[ -n "$any_id" ]]; then
    any_name=$(printf '%s\n' "$rows" | awk -F'\t' -v id="$any_id" '$1==id{print $2; exit}')
    any_state=$(printf '%s\n' "$rows" | awk -F'\t' -v id="$any_id" '$1==id{print $3; exit}')
    log ""
    log "   ⚠️  This project already has a cluster '$any_name' (state: $any_state)."
    log "   Capella allows only one free-tier cluster per organization, so creating"
    log "   another one here would fail."
    read -r -p "   OK to create the app's bucket inside the existing cluster '$any_name'? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      log "   ♻️  Using existing cluster '$any_name': $any_id"
      if [[ "$any_state" == "turnedOff" ]]; then
        log "   Cluster is off — turning it on..."
        api POST "/organizations/${org_id}/projects/${project_id}/clusters/freeTier/${any_id}/activationState" "" > /dev/null
        log "   Cluster wake requested. Waiting for healthy..."
      fi
      echo "$any_id"
      return
    else
      log ""
      log "❌ Not proceeding. To start fresh, delete cluster '$any_name' in this project"
      log "   via the Capella console (Projects → your project → Clusters → ⋮ → Delete),"
      log "   or the Management API, then re-run this script."
      exit 1
    fi
  fi

  log "   Creating new cluster ($CLOUD_PROVIDER / $CLOUD_REGION)..."
  local resp id
  if [[ "$FREE_TIER" == "true" ]]; then
    # Free-tier body: name + cloudProvider.type + cloudProvider.region + cloudProvider.cidr
    # cidr is required even though the schema marks it optional — omitting it causes 422.
    resp=$(api POST "/organizations/${org_id}/projects/${project_id}/clusters/freeTier" \
      "$(jq -n --arg n "$CB_CLUSTER_NAME" --arg p "$CLOUD_PROVIDER" \
               --arg r "$CLOUD_REGION"    --arg c "$CLOUD_CIDR" \
        '{"name":$n,"cloudProvider":{"type":$p,"region":$r,"cidr":$c}}')")
  else
    resp=$(api POST "/organizations/${org_id}/projects/${project_id}/clusters" \
      "$(jq -n --arg n "$CB_CLUSTER_NAME" --arg p "$CLOUD_PROVIDER" --arg r "$CLOUD_REGION" \
        '{"name":$n,"cloudProvider":{"type":$p,"region":$r,"cidr":"10.0.0.0/23"},
          "couchbaseServer":{"version":"7.6"},
          "serviceGroups":[{"node":{"compute":{"cpu":4,"ram":16},
            "disk":{"type":"gp3","storage":50,"iops":3000}},
            "numOfNodes":3,"services":["data","index","query"]}],
          "availability":{"type":"multi"},
          "support":{"plan":"developer pro","timezone":"PT"}}')")
  fi
  id=$(echo "$resp" | jq -r '.id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    log "❌ Cluster creation failed."; exit 1
  fi
  log "   ✅ Cluster created: $id"
  echo "$id"
}

wait_for_cluster() {
  local org_id="$1" project_id="$2" cluster_id="$3"
  local path
  if [[ "$FREE_TIER" == "true" ]]; then
    path="/organizations/${org_id}/projects/${project_id}/clusters/freeTier/${cluster_id}"
  else
    path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}"
  fi
  local resp
  resp=$(wait_for_state "cluster" "$path" "healthy" '.currentState')
  echo "$resp" | jq -r '.id'
}

# ---------------------------------------------------------------------------
# STEP 5 — Bucket (idempotent, returns bucket UUID)
# ---------------------------------------------------------------------------

# Looks up a bucket by name in a cluster without creating anything. Used by
# get_or_create_bucket (below) and by main(), which needs to know -- before it decides
# whether to prompt for an org-wide free-tier cluster redirect -- whether this app's bucket
# is already sitting there from a previous run (if so, nothing new would be created, so
# there's nothing to ask permission for).
bucket_exists_in_cluster() {
  local org_id="$1" project_id="$2" cluster_id="$3" bucket_name="$4"
  local list_resp
  if [[ "$FREE_TIER" == "true" ]]; then
    list_resp=$(api_or_empty GET \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets/freeTier")
  else
    list_resp=$(api_or_empty GET \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets")
  fi
  echo "$list_resp" | jq -r --arg n "$bucket_name" \
    '.data[]? | select(.name == $n) | .id' | head -1
}

get_or_create_bucket() {
  local org_id="$1" project_id="$2" cluster_id="$3"
  log ""
  log "🪣  Step 5: Finding or creating bucket '$CB_BUCKET_NAME'..."

  # Scopes/collections API requires the bucket UUID — NOT the bucket name.
  # Using the name returns 404 "bucket does not exist".
  local existing_id
  existing_id=$(bucket_exists_in_cluster "$org_id" "$project_id" "$cluster_id" "$CB_BUCKET_NAME")

  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    log "   ♻️  Bucket '$CB_BUCKET_NAME' already exists (UUID: $existing_id) — skipping."
    echo "$existing_id"
    return
  fi

  local resp bucket_id
  if [[ "$FREE_TIER" == "true" ]]; then
    resp=$(api POST \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets/freeTier" \
      "$(jq -n --arg n "$CB_BUCKET_NAME" '{"name":$n}')")
  else
    resp=$(api POST \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets" \
      "$(jq -n --arg n "$CB_BUCKET_NAME" '{
        "name":$n,"type":"couchbase","storageBackend":"couchstore",
        "memoryAllocationInMb":256,"bucketConflictResolution":"seqno",
        "durabilityLevel":"none","replicas":1,"flush":false,"timeToLiveInSeconds":0
      }')")
  fi
  bucket_id=$(echo "$resp" | jq -r '.id // empty')
  if [[ -z "$bucket_id" ]]; then
    log "❌ Bucket creation failed — could not extract UUID from response."
    log "   Response: $resp"
    exit 1
  fi
  log "   ✅ Bucket '$CB_BUCKET_NAME' created (UUID: $bucket_id)"
  echo "$bucket_id"
}

# ---------------------------------------------------------------------------
# STEP 6 — Scopes and collections (idempotent — skips existing)
# ---------------------------------------------------------------------------

get_or_create_collections() {
  local org_id="$1" project_id="$2" cluster_id="$3" bucket_id="$4"
  log ""
  log "📂 Step 6: Finding or creating scopes and collections..."

  # Path uses bucket UUID — NOT the bucket name (causes 404 if name is used).
  local base="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets/${bucket_id}"
  local existing_scopes_resp
  existing_scopes_resp=$(api_or_empty GET "${base}/scopes")

  # Track which scopes we've already processed to avoid duplicate scope creates.
  # Use a space-delimited string (no declare -A — requires Bash 4, macOS ships Bash 3.2).
  local scopes_processed=""
  for pair in $COLLECTIONS; do
    local scope collection
    scope="${pair%%/*}"; collection="${pair##*/}"

    # Never use _default scope — always use a named scope.
    if [[ "$scope" == "_default" ]]; then
      log "   ⚠️  Skipping '${pair}' — do not use _default scope. Use a named scope in COLLECTIONS."
      continue
    fi

    # Create named scope if not yet processed this run
    if [[ ! " $scopes_processed " =~ " $scope " ]]; then
      local scope_exists
      scope_exists=$(echo "$existing_scopes_resp" | jq -r --arg s "$scope" \
        '.scopes[]? | select(.name == $s) | .name' | head -1)
      if [[ -n "$scope_exists" ]]; then
        log "   ♻️  Scope '$scope' already exists — skipping."
      else
        log "   Creating scope '$scope'..."
        api POST "${base}/scopes" "{\"name\":\"${scope}\"}" > /dev/null || true
      fi
      scopes_processed+=" $scope"
    fi

    # Create collection if it doesn't exist.
    # maxTTL:0 is required — non-zero TTL causes _sync documents to expire, breaking replication.
    local col_exists
    col_exists=$(echo "$existing_scopes_resp" | jq -r \
      --arg s "$scope" --arg c "$collection" \
      '.scopes[]? | select(.name == $s) | .collections[]? | select(.name == $c) | .name' | head -1)
    if [[ -n "$col_exists" ]]; then
      log "   ♻️  Collection '${scope}/${collection}' already exists — skipping."
    else
      log "   Creating collection '${scope}/${collection}'..."
      api POST "${base}/scopes/${scope}/collections" \
        "{\"name\":\"${collection}\",\"maxTTL\":0}" > /dev/null || true
    fi
  done
  log "   ✅ Collections done."
}

# ---------------------------------------------------------------------------
# STEP 7 — App Service (idempotent)
# ---------------------------------------------------------------------------

get_or_create_app_service() {
  local org_id="$1" project_id="$2" cluster_id="$3"
  log ""
  log "🔧 Step 7: Finding or creating App Service '$CB_APP_SERVICE_NAME'..."

  # Capella allows exactly ONE App Service per cluster (not one per app). So the match here
  # is by clusterId alone, never by name -- a cluster shared with another app already has its
  # one App Service under that app's name, and that's still the right one to reuse. Each app
  # keeps its own data isolated via its own App Endpoint (bucket/scope-scoped, step 9), not by
  # having its own App Service. No prompt needed here: unlike the free-tier-cluster redirect
  # above, this isn't a choice between two valid resources -- there is only ever one App
  # Service per cluster to find, so reusing it is simply correct, not a judgment call.
  local list_resp existing_id existing_state existing_name
  list_resp=$(api_or_empty GET "/organizations/${org_id}/appservices")
  existing_id=$(echo "$list_resp" | jq -r \
    --arg cid "$cluster_id" \
    '.data[]? | select(.clusterId == $cid) | .id' | head -1)

  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    existing_name=$(echo "$list_resp" | jq -r \
      --arg cid "$cluster_id" \
      '.data[]? | select(.clusterId == $cid) | .name' | head -1)
    existing_state=$(echo "$list_resp" | jq -r \
      --arg cid "$cluster_id" \
      '.data[]? | select(.clusterId == $cid) | .currentState' | head -1)
    if [[ "$existing_name" == "$CB_APP_SERVICE_NAME" ]]; then
      log "   ♻️  Found existing App Service (state: $existing_state): $existing_id"
    else
      log "   ♻️  This cluster already has an App Service, '$existing_name' (state: $existing_state,"
      log "      id: $existing_id). Capella allows only one App Service per cluster, so reusing it --"
      log "      this app's data stays isolated via its own App Endpoint ('$CB_ENDPOINT_NAME'), created next."
    fi
    echo "$existing_id"
    return
  fi

  local resp id
  if [[ "$FREE_TIER" == "true" ]]; then
    # Free-tier body: name only — cluster is identified by the path, not body.
    resp=$(api POST \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/freeTier" \
      "$(jq -n --arg n "$CB_APP_SERVICE_NAME" '{"name":$n}')")
  else
    resp=$(api POST \
      "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices" \
      "$(jq -n --arg n "$CB_APP_SERVICE_NAME" \
        '{"name":$n,"compute":{"type":"c3.xlarge","cpu":2,"ram":4}}')")
  fi
  id=$(echo "$resp" | jq -r '.id')
  if [[ -z "$id" || "$id" == "null" ]]; then
    log "❌ App Service creation failed."; exit 1
  fi
  log "   ✅ App Service created: $id"
  echo "$id"
}

wait_for_app_service() {
  local org_id="$1" project_id="$2" cluster_id="$3" app_service_id="$4"
  local path
  if [[ "$FREE_TIER" == "true" ]]; then
    path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/freeTier/${app_service_id}"
  else
    path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}"
  fi
  wait_for_state "App Service" "$path" "healthy" '.currentState' > /dev/null
}

# ---------------------------------------------------------------------------
# STEP 9 — App Endpoint (idempotent)
# ACF is embedded inline at creation time and updated separately in step 9b.
# ---------------------------------------------------------------------------

get_or_create_app_endpoint() {
  local org_id="$1" project_id="$2" cluster_id="$3" app_service_id="$4"
  log ""
  log "🔗 Step 9: Finding or creating App Endpoint '$CB_ENDPOINT_NAME'..."

  local endpoints_path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/appEndpoints"

  # Check if endpoint already exists
  local list_resp existing_name existing_state existing_public_url existing_admin_url
  list_resp=$(api_or_empty GET "$endpoints_path")
  existing_name=$(echo "$list_resp" | jq -r --arg n "$CB_ENDPOINT_NAME" \
    '.data[]? | select(.name == $n) | .name' | head -1)

  if [[ -n "$existing_name" && "$existing_name" != "null" ]]; then
    existing_state=$(echo "$list_resp" | jq -r --arg n "$CB_ENDPOINT_NAME" \
      '.data[]? | select(.name == $n) | .state // "unknown"' | head -1)
    log "   ♻️  App Endpoint '$CB_ENDPOINT_NAME' exists (state: $existing_state)"

    # If still initializing from a previous run, wait for it to finish
    if [[ "$existing_state" == "Initializing" || "$existing_state" == "initializing" ]]; then
      log "   Still initializing — waiting..."
      local ep_resp ep_state ep_elapsed=0
      while true; do
        ep_resp=$(api GET "${endpoints_path}/${CB_ENDPOINT_NAME}")
        ep_state=$(echo "$ep_resp" | jq -r '.state // "unknown"')
        printf "   [%3ds] state: %s\n" "$ep_elapsed" "$ep_state" >&2
        if [[ "$ep_state" != "Initializing" && "$ep_state" != "initializing" ]]; then break; fi
        if (( ep_elapsed >= 300 )); then log "❌ Timed out waiting for endpoint."; exit 1; fi
        sleep 10
        (( ep_elapsed += 10 )) || true
      done
      existing_state="$ep_state"
    fi

    existing_public_url=$(echo "$list_resp" | jq -r --arg n "$CB_ENDPOINT_NAME" \
      '.data[]? | select(.name == $n) | .publicURL // ""' | head -1)
    existing_admin_url=$(echo "$list_resp" | jq -r --arg n "$CB_ENDPOINT_NAME" \
      '.data[]? | select(.name == $n) | .adminURL // ""' | head -1)
    echo "${existing_public_url}	${existing_admin_url}"
    return
  fi

  # Build scopes config for the endpoint body.
  # Format: {"scopeName":{"collections":{"collName":{"accessControlFunction":"..."}}}}
  # ACF is embedded here as a baseline; step 9b will always update it with the latest.
  local scopes_json="{}"
  for pair in $COLLECTIONS; do
    local scope collection
    scope="${pair%%/*}"; collection="${pair##*/}"

    local fn_content='function(doc, oldDoc){ channel(doc.channels); }'
    local fn_file="${SYNC_FUNCTIONS_DIR}/${collection}-sync-function.js"
    if [[ -f "$fn_file" ]]; then
      # Strip comments before embedding — non-ASCII in comments breaks the JS parser
      fn_content=$(cat "$fn_file" \
        | sed '/^[[:space:]]*\/\*\*/,/\*\//d' \
        | sed 's|[[:space:]]*//.*$||g' \
        | sed '/^[[:space:]]*$/d')
      log "   Using ACF: $fn_file"
    else
      log "   ⚠️  ACF not found at '$fn_file' — embedding passthrough default."
      log "      Set SYNC_FUNCTIONS_DIR to point to your sync-functions directory."
    fi

    local col_entry
    col_entry=$(jq -n --arg fn "$fn_content" '{"accessControlFunction":$fn}')
    scopes_json=$(echo "$scopes_json" | jq \
      --arg scope "$scope" --arg coll "$collection" --argjson col "$col_entry" \
      '.[$scope].collections[$coll] = $col')
  done

  local body
  body=$(jq -n \
    --arg name "$CB_ENDPOINT_NAME" \
    --arg bucket "$CB_BUCKET_NAME" \
    --argjson scopes "$scopes_json" \
    '{"name":$name,"bucket":$bucket,"scopes":$scopes,"deltaSyncEnabled":false}')

  # POST returns 201 with no body — must GET after creation to retrieve publicURL and adminURL
  api POST "$endpoints_path" "$body" > /dev/null
  log "   Waiting for App Endpoint to finish initializing..."
  local get_resp state elapsed=0
  while true; do
    get_resp=$(api GET "${endpoints_path}/${CB_ENDPOINT_NAME}")
    state=$(echo "$get_resp" | jq -r '.state // "unknown"')
    printf "   [%3ds] state: %s\n" "$elapsed" "$state" >&2
    if [[ "$state" != "Initializing" && "$state" != "initializing" ]]; then break; fi
    if (( elapsed >= 300 )); then log "❌ Timed out waiting for endpoint to initialize."; exit 1; fi
    sleep 10
    (( elapsed += 10 )) || true
  done
  # Endpoint is now Offline — keep it Offline until ACF is verified and users are set up.
  log "   ✅ App Endpoint initialized (state: $state — kept Offline until users are configured)"

  local public_url admin_url
  public_url=$(echo "$get_resp" | jq -r '.publicURL // ""')
  admin_url=$(echo "$get_resp" | jq -r '.adminURL // ""')
  echo "${public_url}	${admin_url}"
}

# ---------------------------------------------------------------------------
# STEP 9b — Update Access Control Function (always runs — even on re-run)
# ---------------------------------------------------------------------------

update_access_control_functions() {
  local org_id="$1" project_id="$2" cluster_id="$3" app_service_id="$4"
  local base_path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/appEndpoints"

  log ""
  log "📋 Step 9b: Updating Access Control Functions..."

  for pair in $COLLECTIONS; do
    local scope collection
    scope="${pair%%/*}"; collection="${pair##*/}"

    local fn_file="${SYNC_FUNCTIONS_DIR}/${collection}-sync-function.js"
    if [[ ! -f "$fn_file" ]]; then
      echo ""
      echo "❌ FATAL: Access Control Function not found at:"
      echo "   $fn_file"
      echo ""
      echo "   (Resolved SYNC_FUNCTIONS_DIR = ${SYNC_FUNCTIONS_DIR})"
      echo "   Without the correct ACF, ALL document pushes will fail with HTTP 403."
      echo ""
      echo "   Fix one of:"
      echo "     • Make sure a file named <collection>-sync-function.js exists in that folder"
      echo "       (one per entry in COLLECTIONS='${COLLECTIONS}')."
      echo "     • Set SYNC_FUNCTIONS_DIR to the folder that contains them. It is resolved"
      echo "       relative to THIS script's location, so 'sync-functions' works when the"
      echo "       folder sits next to setup-capella.sh — do NOT add a project-name prefix."
      echo "   Then re-run the script (safe to re-run)."
      echo ""
      exit 1
    fi
    log "   Using: $fn_file"

    # Strip ALL comments before sending — non-ASCII characters in comments break the JS parser.
    # Content-Type MUST be application/javascript — the API rejects application/json here.
    # The keyspace format is: endpointName.scope.collection (all three parts required).
    local fn_clean keyspace http_code
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
    if [[ "$http_code" == "200" || "$http_code" == "201" || "$http_code" == "204" ]]; then
      log "   ✅ ACF updated for keyspace: ${keyspace}"
    else
      log "   ❌ ACF update failed HTTP $http_code for keyspace: ${keyspace}"
    fi
  done
}

# ---------------------------------------------------------------------------
# STEP 10 — Create App Services Admin Credential via Capella Management API
# ---------------------------------------------------------------------------

create_admin_credential() {
  local org_id="$1" project_id="$2" cluster_id="$3" app_service_id="$4"
  echo ""
  echo "🔐 Step 10: Creating App Services Admin Credential '${APPSVC_ADMIN_USER}'..."

  local path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/adminUsers"

  # NOTE: an Admin Credential's password CANNOT be read back or updated via the API
  # (PUT /adminUsers/{id} only changes endpoint access). So "skip if exists" would leave
  # a stale password and every later Admin-REST call would fail with 401. To make re-runs
  # idempotent AND ensure the credential's password matches APPSVC_ADMIN_PASS, we
  # delete-and-recreate it. This is safe because APPSVC_ADMIN_USER is app-specific
  # (must be unique per app) — it only touches this app's credential.
  local list_resp existing_id
  list_resp=$(api_or_empty GET "$path")
  existing_id=$(echo "$list_resp" | jq -r --arg n "$APPSVC_ADMIN_USER" \
    '.data[]? | select(.name == $n) | .id' | head -1)
  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    echo "   ♻️  Admin credential '${APPSVC_ADMIN_USER}' exists — recreating so the current password applies (password is not updatable via API)."
    api_or_empty DELETE "${path}/${existing_id}" > /dev/null
  fi

  api POST "$path" \
    "$(jq -n --arg n "$APPSVC_ADMIN_USER" --arg p "$APPSVC_ADMIN_PASS" \
      '{"name":$n,"password":$p,"enableBucketLevelAccess":true,"access":{"accessAllEndpoints":true}}')" > /dev/null
  echo "   ✅ Admin credential '${APPSVC_ADMIN_USER}' ready."
}

# ---------------------------------------------------------------------------
# STEP 11 — App Services allowed CIDR (required to reach Admin REST API)
# ---------------------------------------------------------------------------

setup_allowed_cidr() {
  local org_id="$1" project_id="$2" cluster_id="$3" app_service_id="$4"
  echo ""
  echo "🌐 Step 11: Configuring App Services allowed CIDR (0.0.0.0/0)..."

  local path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/allowedcidrs"

  local list_resp existing
  list_resp=$(api_or_empty GET "$path")
  existing=$(echo "$list_resp" | jq -r '.data[]? | select(.cidr == "0.0.0.0/0") | .cidr' | head -1)
  if [[ -n "$existing" ]]; then
    echo "   ♻️  0.0.0.0/0 already allowed — skipping."
    return
  fi

  api POST "$path" \
    '{"cidr":"0.0.0.0/0","comment":"Allow Admin REST API access — restrict for production"}' > /dev/null
  echo "   ✅ CIDR 0.0.0.0/0 added."
}

# ---------------------------------------------------------------------------
# STEP 12 — Create App Roles and App Users via Admin REST API
#
# Key rules (learned from real bugs):
#
# 1. activationStatus: use curl with || true — NOT api(). api() exits on 4xx.
#    On re-runs the endpoint is already Online → activationStatus returns 4xx → api() kills script.
#
# 2. collection_access format is REQUIRED for App Services with named scopes.
#    Flat top-level admin_channels is old Sync Gateway pre-collections syntax — silently ignored.
#    Even when the API returns 201, channels never appear in the UI and never take effect.
#
# 3. Admin channel access belongs on the App ROLE, not in the ACF -- this is a design choice
#    (a one-time grant at role-creation, not re-issued per write), NOT a proven platform
#    limitation. Couchbase's access() docs document a "role:" prefix for granting a whole role
#    (access(["role:admin"], channel)), same engine version App Services runs, no Capella-specific
#    exception noted -- so it likely works here too, just not independently verified live. See
#    couchbase-mobile-access-control-function's role-channel-rules.md Rule B for the full story.
#    Every user with admin_roles:["admin"] automatically inherits the role's collection_access
#    from this static grant either way.
#
# 4. POST→PUT-on-409 for all roles/users — POST-only silently leaves stale config on re-runs.
# ---------------------------------------------------------------------------

setup_app_users() {
  local base_url="$1" org_id="$2" project_id="$3" cluster_id="$4" app_service_id="$5"
  local endpoints_path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/appEndpoints"

  echo ""
  echo "👥 Step 12: Setting up App Roles and App Users..."
  echo ""
  echo "   ℹ️  About to create 'manager'/'bob' App Users using the password currently set for"
  echo "      MANAGER_PASS / BOB_PASS in provision.env (default: 'Password1!' unless you changed it)."
  echo "      To use a different password instead: press Ctrl+C now, edit MANAGER_PASS and/or"
  echo "      BOB_PASS in provision.env, then re-run: source provision.env && ./setup-capella.sh"
  echo "      (safe to re-run — already-provisioned resources are skipped; only the changed"
  echo "      password gets applied to the existing user)."
  echo "      Press Enter to continue now, or wait 20 seconds."
  # read -t 1 in a loop: gives a live countdown AND lets Enter skip the wait immediately,
  # without blocking indefinitely if the user does nothing (times out and continues on its own).
  # Whatever is typed before Enter is discarded, never inspected -- this only detects "did they
  # press Enter," never captures input as a value.
  for _i in $(seq 20 -1 1); do
    printf '\r   Continuing in %2d seconds (press Enter to skip)...   ' "$_i"
    if read -t 1 -r _skip_wait; then
      break
    fi
  done
  printf '\r%s\n' "   Continuing...                                                              "

  # Bring endpoint Online — required before Admin REST API calls.
  # Use curl with || true, NOT api(). api() exits on 4xx.
  # On re-runs endpoint is already Online → activationStatus returns 4xx → api() would kill script.
  echo "   Ensuring App Endpoint is Online..."
  local activate_code
  activate_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${BASE_URL}${endpoints_path}/${CB_ENDPOINT_NAME}/activationStatus" \
    -H "Authorization: Bearer ${CB_API_KEY}" \
    -H "Content-Type: application/json") || true
  if [[ "$activate_code" == "200" || "$activate_code" == "201" || "$activate_code" == "204" ]]; then
    echo "   ✅ App Endpoint brought Online."
  elif [[ "$activate_code" == "409" || "$activate_code" == "422" ]]; then
    echo "   ✅ App Endpoint already Online."
  else
    echo "   ⚠️  activationStatus returned HTTP $activate_code — endpoint may not be Online yet."
  fi
  echo ""
  echo "   Using Admin REST API base: ${base_url}"
  echo ""

  # build_collection_access — builds collection_access JSON from COLLECTIONS env var.
  # App Services with named scopes REQUIRES this format. Flat admin_channels is silently ignored.
  #
  # Example: COLLECTIONS='todo/todos', channels_json='["admin"]' produces:
  #   {"todo": {"todos": {"admin_channels": ["admin"]}}}
  build_collection_access() {
    local channels_json="$1"   # e.g. '["admin"]' or '["bob"]'
    local ca="{}"
    for pair in $COLLECTIONS; do
      local scope="${pair%%/*}" collection="${pair##*/}"
      ca=$(echo "$ca" | jq \
        --arg s "$scope" --arg c "$collection" --argjson ch "$channels_json" \
        '.[$s][$c].admin_channels = $ch')
    done
    echo "$ca"
  }

  # ── Admin Role ──────────────────────────────────────────────────────────────
  # Admin channel access comes from admin_channels on the ROLE — not from the ACF.
  # Every user with admin_roles:["admin"] inherits this role's collection_access automatically.
  # POST→PUT-on-409: always update existing role so re-runs never leave stale config.
  echo "   Creating/updating 'admin' App Role..."
  local admin_ca role_body role_resp role_code
  admin_ca=$(build_collection_access '["admin"]')
  role_body=$(jq -n --arg name "admin" --argjson ca "$admin_ca" \
    '{"name":$name,"collection_access":$ca}')
  role_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_role/" \
    -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
    -H "Content-Type: application/json" \
    -d "$role_body") || true
  role_code=$(echo "$role_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
  if [[ "$role_code" == "409" ]]; then
    local role_put_code
    role_put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_role/admin" \
      -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
      -H "Content-Type: application/json" \
      -d "$role_body") || true
    echo "   ✅ App Role 'admin' updated (collection_access with admin channel) — HTTP $role_put_code"
  elif [[ "$role_code" == "201" ]]; then
    echo "   ✅ App Role 'admin' created (collection_access with admin channel)"
  else
    echo "   ⚠️  App Role POST returned HTTP $role_code"
    echo "      Body: $(echo "$role_resp" | sed 's/HTTPSTATUS:[0-9]*$//')"
  fi

  # ── Manager App User ────────────────────────────────────────────────────────
  # admin_roles:["admin"] → manager inherits admin channel from the role's collection_access.
  # No collection_access field needed — the role provides it.
  # POST→PUT-on-409 to upsert.
  echo "   Creating/updating '${MANAGER_USER}' App User..."
  local mgr_body mgr_resp mgr_code
  mgr_body=$(jq -n --arg n "$MANAGER_USER" --arg p "$MANAGER_PASS" \
    '{"name":$n,"password":$p,"admin_roles":["admin"]}')
  mgr_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_user/" \
    -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
    -H "Content-Type: application/json" \
    -d "$mgr_body") || true
  mgr_code=$(echo "$mgr_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
  if [[ "$mgr_code" == "409" ]]; then
    local mgr_put_code
    mgr_put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_user/${MANAGER_USER}" \
      -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
      -H "Content-Type: application/json" \
      -d "$mgr_body") || true
    echo "   ✅ App User '${MANAGER_USER}' updated (role: admin, inherits admin channel) — HTTP $mgr_put_code"
  elif [[ "$mgr_code" == "201" ]]; then
    echo "   ✅ App User '${MANAGER_USER}' created (role: admin, inherits admin channel)"
  else
    echo "   ⚠️  App User '${MANAGER_USER}' POST returned HTTP $mgr_code"
    echo "      Body: $(echo "$mgr_resp" | sed 's/HTTPSTATUS:[0-9]*$//')"
  fi

  # ── Bob App User ────────────────────────────────────────────────────────────
  # Regular user — collection_access channel MUST exactly match the username.
  # This seeds the per-user channel so their assigned docs sync to their device.
  # POST→PUT-on-409 to upsert.
  echo "   Creating/updating 'bob' App User..."
  local bob_ca bob_body bob_resp bob_code
  bob_ca=$(build_collection_access '["bob"]')
  bob_body=$(jq -n --arg p "$BOB_PASS" --argjson ca "$bob_ca" \
    '{"name":"bob","password":$p,"collection_access":$ca}')
  bob_resp=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${base_url}/_user/" \
    -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
    -H "Content-Type: application/json" \
    -d "$bob_body") || true
  bob_code=$(echo "$bob_resp" | tr -d '\n' | grep -o 'HTTPSTATUS:[0-9]*' | cut -d: -f2)
  if [[ "$bob_code" == "409" ]]; then
    local bob_put_code
    bob_put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${base_url}/_user/bob" \
      -u "${APPSVC_ADMIN_USER}:${APPSVC_ADMIN_PASS}" \
      -H "Content-Type: application/json" \
      -d "$bob_body") || true
    echo "   ✅ App User 'bob' updated (collection_access channel: bob) — HTTP $bob_put_code"
  elif [[ "$bob_code" == "201" ]]; then
    echo "   ✅ App User 'bob' created (collection_access channel: bob)"
  else
    echo "   ⚠️  App User 'bob' POST returned HTTP $bob_code"
    echo "      Body: $(echo "$bob_resp" | sed 's/HTTPSTATUS:[0-9]*$//')"
  fi

  echo ""
  echo "   ⚠️  Change default passwords before sharing with real users."
}

# ---------------------------------------------------------------------------
# Org-wide free-tier cluster discovery (FREE_TIER only, called from main() before project /
# cluster resolution)
#
# Capella allows only ONE free-tier cluster per organization, and it can be in ANY project --
# not necessarily the one CB_PROJECT_NAME names. Confirmed twice against a real account: once
# where the existing cluster was in a different project than CB_PROJECT_NAME, and once where
# the org had multiple projects sharing the exact same name and the free-tier cluster was in a
# different one of those duplicates than get_or_create_project()'s name lookup would pick. A
# per-project check, or a name-based check, misses both cases -- a target project (or a
# same-named duplicate of it) can have zero clusters and still 422 on creation, because the
# org's one free-tier slot is used somewhere name matching can't distinguish.
#
# Scans every project in the org; for each cluster found, confirms it's actually the free-tier
# one via the real free-tier get-by-ID endpoint (GET .../clusters/freeTier/{clusterId} --
# assumed to 404 for a non-free-tier cluster, by REST convention; not independently confirmed
# against a real paid cluster in this org -- watch for this if the org ever mixes paid and
# free-tier clusters). A paid cluster elsewhere does NOT count against the free-tier limit and
# must not block a fresh free-tier creation, which is why this check exists rather than
# treating "any cluster anywhere" as a conflict.
#
# Prints "<projectId>\t<projectName>\t<clusterId>\t<clusterName>\t<clusterState>" for the first
# confirmed free-tier cluster found, or nothing if the org has none yet.
# ---------------------------------------------------------------------------

find_org_freetier_cluster() {
  local org_id="$1"
  log ""
  log "🔍 Checking the whole organization for an existing free-tier cluster..."

  local projects_resp proj_rows
  projects_resp=$(api_or_empty GET "/organizations/${org_id}/projects")
  proj_rows=$(echo "$projects_resp" | jq -r '.data[]? | [(.id//empty),(.name//empty)] | @tsv' 2>/dev/null)
  if [[ -z "$proj_rows" ]]; then
    log "   No projects found — nothing to check."
    return 0
  fi

  local pid pname
  while IFS=$'\t' read -r pid pname; do
    [[ -z "$pid" ]] && continue
    local clist crows
    clist=$(api_or_empty GET "/organizations/${org_id}/projects/${pid}/clusters")
    crows=$(_cluster_rows "$clist")
    [[ -z "$crows" ]] && continue
    local cid cname cstate
    while IFS=$'\t' read -r cid cname cstate; do
      [[ -z "$cid" ]] && continue
      local ft_check
      ft_check=$(api_or_empty GET "/organizations/${org_id}/projects/${pid}/clusters/freeTier/${cid}")
      if [[ -n "$ft_check" ]]; then
        log "   Found free-tier cluster '$cname' in project '$pname' ($pid)."
        printf '%s\t%s\t%s\t%s\t%s\n' "$pid" "$pname" "$cid" "$cname" "$cstate"
        return 0
      fi
    done <<< "$crows"
  done <<< "$proj_rows"

  log "   No existing free-tier cluster found in this organization."
  return 0
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

main() {
  check_deps
  validate_config

  echo ""
  echo "=================================================="
  echo "  Capella Free Tier Backend Setup"
  echo "  (Safe to re-run — skips existing resources)"
  echo "=================================================="
  echo "  Project:     $CB_PROJECT_NAME"
  echo "  Cluster:     $CB_CLUSTER_NAME ($CLOUD_PROVIDER / $CLOUD_REGION)"
  echo "  Bucket:      $CB_BUCKET_NAME"
  echo "  App Service: $CB_APP_SERVICE_NAME"
  echo "  Endpoint:    $CB_ENDPOINT_NAME"
  echo "  Collections: $COLLECTIONS"
  echo "=================================================="
  echo ""

  local org_id project_id cluster_id bucket_id app_service_id

  org_id=$(get_org_id)
  if [[ -z "$org_id" || "$org_id" == "null" ]]; then
    echo "❌ Could not resolve org ID."; exit 1
  fi

  # Free-tier only: resolve project+cluster via an org-wide scan FIRST. Capella's
  # 1-free-tier-cluster-per-org limit can be sitting in a project other than CB_PROJECT_NAME
  # names, or in a different, same-named, duplicate project if the org has more than one
  # project sharing that name -- both confirmed real scenarios. When a match is found, its
  # concrete project/cluster IDs are used directly (never re-derived by name), which is what
  # keeps this safe even with duplicate project names. Falls through to the normal name-based
  # get_or_create_project / get_or_create_cluster flow only when nothing is found.
  if [[ "$FREE_TIER" == "true" ]]; then
    local org_match
    org_match=$(find_org_freetier_cluster "$org_id")
    if [[ -n "$org_match" ]]; then
      local m_pid m_pname m_cid m_cname m_cstate
      IFS=$'	' read -r m_pid m_pname m_cid m_cname m_cstate <<< "$org_match"
      if [[ "$m_pname" == "$CB_PROJECT_NAME" && "$m_cname" == "$CB_CLUSTER_NAME" ]]; then
        log "   ♻️  This matches '$CB_PROJECT_NAME' / '$CB_CLUSTER_NAME' — proceeding normally."
        project_id="$m_pid"
        cluster_id="$m_cid"
      else
        local existing_bucket_id
        existing_bucket_id=$(bucket_exists_in_cluster "$org_id" "$m_pid" "$m_cid" "$CB_BUCKET_NAME")
        if [[ -n "$existing_bucket_id" && "$existing_bucket_id" != "null" ]]; then
          # Already redirected here on a previous run -- this app's bucket is already in
          # place, so nothing new would be created. No need to ask again every time; just
          # say where we ended up.
          log ""
          log "   ♻️  Using cluster '$m_cname' in project '$m_pname' — bucket '$CB_BUCKET_NAME' is"
          log "   already there from a previous run."
          project_id="$m_pid"
          cluster_id="$m_cid"
        else
          log ""
          log "   ⚠️  This organization's one free-tier cluster is '$m_cname' (state: $m_cstate),"
          log "   in project '$m_pname' — not '$CB_PROJECT_NAME' / '$CB_CLUSTER_NAME'. Capella"
          log "   allows only 1 free-tier cluster per organization, so creating a new one here"
          log "   would fail."
          read -r -p "   OK to create this app's bucket inside '$m_cname' in project '$m_pname' instead? [y/N] " ans
          if [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            project_id="$m_pid"
            cluster_id="$m_cid"
            log "   ♻️  Using existing cluster '$m_cname' in project '$m_pname': $m_cid"
          else
            log ""
            log "❌ Not proceeding. To start fresh, delete cluster '$m_cname' in project '$m_pname'"
            log "   via the Capella console, or the Management API, then re-run this script."
            exit 1
          fi
        fi
      fi
      if [[ "$m_cstate" == "turnedOff" ]]; then
        log "   Cluster is off — turning it on..."
        api POST "/organizations/${org_id}/projects/${m_pid}/clusters/freeTier/${m_cid}/activationState" "" > /dev/null
        log "   Cluster wake requested. Waiting for healthy..."
      fi
    fi
  fi

  if [[ -z "${project_id:-}" ]]; then
    project_id=$(get_or_create_project "$org_id")
    if [[ -z "$project_id" || "$project_id" == "null" ]]; then
      echo "❌ Could not get project ID."; exit 1
    fi
  fi

  if [[ -z "${cluster_id:-}" ]]; then
    cluster_id=$(get_or_create_cluster "$org_id" "$project_id")
    if [[ -z "$cluster_id" || "$cluster_id" == "null" ]]; then
      echo "❌ Could not get cluster ID."; exit 1
    fi
  fi
  cluster_id=$(wait_for_cluster "$org_id" "$project_id" "$cluster_id")

  bucket_id=$(get_or_create_bucket "$org_id" "$project_id" "$cluster_id")
  if [[ -z "$bucket_id" || "$bucket_id" == "null" ]]; then
    echo "❌ Could not get bucket UUID."; exit 1
  fi

  get_or_create_collections "$org_id" "$project_id" "$cluster_id" "$bucket_id"

  app_service_id=$(get_or_create_app_service "$org_id" "$project_id" "$cluster_id")
  if [[ -z "$app_service_id" || "$app_service_id" == "null" ]]; then
    echo "❌ Could not get App Service ID."; exit 1
  fi

  # App Endpoint requires App Service to be healthy first
  wait_for_app_service "$org_id" "$project_id" "$cluster_id" "$app_service_id"

  local endpoint_urls
  endpoint_urls=$(get_or_create_app_endpoint "$org_id" "$project_id" "$cluster_id" "$app_service_id")

  # Always update Access Control Functions — runs whether endpoint was just created or already existed
  update_access_control_functions "$org_id" "$project_id" "$cluster_id" "$app_service_id"

  local public_url admin_url wss_url
  public_url=$(echo "$endpoint_urls" | cut -f1)
  admin_url=$(echo "$endpoint_urls" | cut -f2)

  # Derive WSS URL from publicURL — just swap the scheme, don't append endpoint name again
  if [[ -n "$public_url" && "$public_url" != "null" && "$public_url" != "" ]]; then
    wss_url=$(echo "$public_url" | sed 's|^https://|wss://|')
  else
    wss_url="wss://<app-service-host>/<endpoint-name>"
    echo "⚠️  Could not detect endpoint URL — find it in Capella UI → App Services → Connect." >&2
  fi

  # adminURL comes from the API — never hardcode the port (AWS=4985, GCP=443, etc.)
  if [[ -z "$admin_url" || "$admin_url" == "null" || "$admin_url" == "" ]]; then
    admin_url="<see Capella UI → App Services → endpoint → Connect → Admin REST tab>"
  fi

  create_admin_credential "$org_id" "$project_id" "$cluster_id" "$app_service_id"
  setup_allowed_cidr "$org_id" "$project_id" "$cluster_id" "$app_service_id"

  if [[ -n "$admin_url" && "$admin_url" != "null" && "$admin_url" != *"see Capella"* ]]; then
    setup_app_users "$admin_url" "$org_id" "$project_id" "$cluster_id" "$app_service_id"
  else
    echo "⚠️  Admin URL not available — skipping App User setup."
    echo "   Find it in Capella UI → App Services → endpoint → Connect → Admin REST tab."
  fi

  # Auto-find and update the client config with the WSS URL, by detection:
  #   iOS      → Info.plist  AppServicesEndpointURL   (macOS `plutil`)
  #   Android  → local.properties  cbl.endpointUrl    (beside settings.gradle[.kts])
  #   else     → just print the URL for you to set manually.
  # Provisioning itself is unaffected regardless of which (if any) is found.
  if [[ -n "$wss_url" && "$wss_url" != *"<app-service"* ]]; then
    local wrote_config=""

    # --- iOS: Info.plist via plutil ---
    local info_plist
    info_plist=$(find . -name "Info.plist" \
      -not -path "*/DerivedData/*" \
      -not -path "*/.xcodeproj/*" \
      -not -path "*/.framework/*" \
      -not -path "*/Pods/*" \
      2>/dev/null | head -1)
    if [[ -n "$info_plist" ]] && command -v plutil >/dev/null 2>&1; then
      echo ""
      echo "📝 Writing WSS URL to ${info_plist}..."
      plutil -replace AppServicesEndpointURL -string "$wss_url" "$info_plist" 2>/dev/null || \
        plutil -insert AppServicesEndpointURL -string "$wss_url" "$info_plist" 2>/dev/null || \
        echo "   ⚠️  Could not write Info.plist automatically — set AppServicesEndpointURL = ${wss_url} manually."
      echo "   ✅ Info.plist updated: AppServicesEndpointURL = ${wss_url}"
      wrote_config="ios"
    fi

    # --- Android: local.properties beside settings.gradle(.kts) ---
    if [[ -z "$wrote_config" ]]; then
      local gradle_settings android_dir local_props
      gradle_settings=$(find . \( -name "settings.gradle" -o -name "settings.gradle.kts" \) \
        -not -path "*/build/*" -not -path "*/.gradle/*" 2>/dev/null | head -1)
      if [[ -n "$gradle_settings" ]]; then
        android_dir=$(dirname "$gradle_settings")
        local_props="${android_dir}/local.properties"
        echo ""
        echo "📝 Writing WSS URL to ${local_props} (cbl.endpointUrl)..."
        touch "$local_props" 2>/dev/null || true
        if grep -q '^cbl\.endpointUrl=' "$local_props" 2>/dev/null; then
          sed -i.bak "s|^cbl\.endpointUrl=.*|cbl.endpointUrl=${wss_url}|" "$local_props" && rm -f "${local_props}.bak"
        else
          printf 'cbl.endpointUrl=%s\n' "$wss_url" >> "$local_props"
        fi
        echo "   ✅ local.properties updated: cbl.endpointUrl = ${wss_url}"
        echo "   ↻  Re-sync Gradle in Android Studio so BuildConfig picks up the URL."
        wrote_config="android"
      fi
    fi

    if [[ -z "$wrote_config" ]]; then
      echo "   ℹ️  No iOS Info.plist or Android local.properties found here"
      echo "      (fine on Linux/Windows or other clients)."
      echo "      Set your client's App Services endpoint to: ${wss_url}"
    fi
  fi

  echo ""
  echo "=================================================="
  echo " DONE! Backend is fully configured."
  echo "=================================================="
  echo ""
  echo " WSS URL: ${wss_url}"
  echo ""
  echo "=================================================="
  echo " HOW TO TEST OFFLINE-FIRST SYNC"
  echo "=================================================="
  echo ""
  if [[ "${wrote_config:-}" == "android" ]]; then
    echo " Test with two emulators (Android Studio can run BOTH at once):"
    echo ""
    echo "   1. Android Studio: open Device Manager, start Emulator 1 (e.g. Pixel 8, API 35)."
    echo "      Pick it in the target dropdown (top toolbar) -> click Run (the green triangle, Ctrl/Cmd+R)."
    echo "      Confirm the app launches, then sign in as ${MANAGER_USER} / ${MANAGER_PASS}."
    echo "   2. In Device Manager, start Emulator 2 (e.g. Pixel 8 Pro). Android runs both side by side —"
    echo "      no need to stop the first (unlike Xcode)."
    echo "   3. Pick Emulator 2 in the target dropdown -> click Run again. Sign in as bob / ${BOB_PASS}."
    echo "      Both apps are now live side by side."
    echo "   4. As ${MANAGER_USER}: create a record, assign it to bob -> watch it appear & sync on bob's emulator;"
    echo "      bob updates status -> ${MANAGER_USER} sees it live."
    echo ""
    echo "   Note: the green Run triangle builds, installs AND launches on the selected emulator. To relaunch"
    echo "   a stopped app without rebuilding, tap its icon in the emulator's app drawer."
    echo ""
    echo " Offline-first: in the app's Settings use the Offline toggle (or toggle the emulator's network via"
    echo " Extended controls (...) -> Cellular / Wi-Fi, or airplane mode), make changes locally, then go"
    echo " back online — pending changes sync automatically."
  elif [[ "${wrote_config:-}" == "ios" ]]; then
    echo " Test with two simulators (Xcode runs ONE destination at a time — run each in turn):"
    echo ""
    echo "   1. Xcode: set destination to Simulator 1 (e.g. iPhone 16) -> Cmd+R."
    echo "      Confirm the app launches, then sign in as ${MANAGER_USER} / ${MANAGER_PASS}."
    echo "      (When you run the app, ignore any 'Signing requires a development team' warning — not needed for the Simulator.)"
    echo "   2. Xcode: Stop the run (square button / Cmd+.). Sim 1's app is killed but stays installed."
    echo "   3. Xcode: change destination to Simulator 2 (e.g. iPhone 16 Pro) -> Cmd+R. Sign in as bob / ${BOB_PASS}."
    echo "   4. On Simulator 1, TAP the app icon to relaunch it (runs standalone — needs the embedded framework)."
    echo "      Both apps are now live side by side."
    echo "   5. As ${MANAGER_USER}: create a record, assign it to bob -> watch it appear & sync on bob's simulator;"
    echo "      bob updates status -> ${MANAGER_USER} sees it live."
    echo ""
    echo "   Note: Cmd+B only COMPILES — it does NOT install/launch on a simulator. Use Cmd+R per destination."
    echo ""
    echo " Offline-first: in the app's Settings use the Offline toggle (or turn the simulator's Wi-Fi off),"
    echo " make changes locally, then go back online — pending changes sync automatically."
  else
    echo " Test offline-first sync with two client instances (two devices / emulators / simulators):"
    echo ""
    echo "   1. Launch the app on client 1, sign in as ${MANAGER_USER} / ${MANAGER_PASS}."
    echo "   2. Launch the app on client 2, sign in as bob / ${BOB_PASS}."
    echo "   3. As ${MANAGER_USER}: create a record, assign it to bob -> watch it sync to bob;"
    echo "      bob updates status -> ${MANAGER_USER} sees it live."
    echo ""
    echo " Offline-first: take a client offline (the app's Offline toggle or the device's network), make"
    echo " changes locally, then go back online — pending changes sync automatically."
  fi
  echo ""
  echo "=================================================="
  echo " App Services Admin Credential: ${APPSVC_ADMIN_USER}  (password: see APPSVC_ADMIN_PASS in provision.env — never printed)"
  echo " (Infrastructure only — use this to add App Users via Admin REST API)"
  echo ""
  echo " ⚠️  Before running the curl commands below in THIS terminal: run \"source provision.env\""
  echo "    again first. If APPSVC_ADMIN_PASS was blank and got auto-generated during this run, your"
  echo "    shell still has the OLD (blank) value from before the script started — the script updated"
  echo "    the file, not your shell's environment. Re-sourcing picks up the real value. Check with:"
  echo "    echo \$APPSVC_ADMIN_PASS  (if that's empty, you need to re-source)."
  echo ""
  # Build a ready-to-paste collection_access literal for an example user "alice"
  # (grants the "alice" channel across every scope/collection this backend provisioned),
  # so the printed curl needs neither jq nor the COLLECTIONS env var.
  local _alice_ca="{}"
  for _pair in $COLLECTIONS; do
    _alice_ca=$(echo "$_alice_ca" | jq \
      --arg s "${_pair%%/*}" --arg c "${_pair##*/}" \
      '.[$s][$c].admin_channels = ["alice"]')
  done
  local _alice_body
  _alice_body=$(jq -cn --argjson ca "$_alice_ca" \
    '{"name":"alice","password":"CHANGE-ME","collection_access":$ca}')
  echo " To add a regular App User with non-admin role, like the bob user above (e.g. alice) — copy/paste, no jq needed:"
  echo "   # Use collection_access — flat admin_channels is silently ignored by App Services"
  echo "   # \$APPSVC_ADMIN_USER / \$APPSVC_ADMIN_PASS come from your shell — re-source provision.env"
  echo "   # first (see warning above) if you haven't since this run. Never printed here either way."
  echo "   curl -X POST \"${admin_url}/_user/\" \\"
  echo '     -u "$APPSVC_ADMIN_USER:$APPSVC_ADMIN_PASS" \'
  echo "     -H 'Content-Type: application/json' \\"
  echo "     -d '${_alice_body}'"
  echo ""
  echo " The app only recognizes one App User as admin — that's hardcoded client-side, not"
  echo " derived from App Services roles/channels. Creating another App User with"
  echo " admin_roles:[\"admin\"] grants the role on the backend, but the app has no way to"
  echo " reflect it, so it would just be confusing. Regular App Users (like alice above) are"
  echo " the right way to add more test accounts."
  echo ""
  echo "=================================================="
}

main "$@"
