#!/usr/bin/env bash
# =============================================================================
# teardown-capella.sh — deletes ONLY the Capella backend resources that
# setup-capella.sh actually created for this demo/app.
#
# SAFE BY DESIGN: never deletes a Project, Cluster, or App Service that setup-capella.sh
# found already existing rather than created — those may be shared with another app or
# demo on the same cluster/org. Provenance comes from PROJECT_CREATED_BY_SCRIPT /
# CLUSTER_CREATED_BY_SCRIPT / APP_SERVICE_CREATED_BY_SCRIPT in provision.env, which
# setup-capella.sh now records on every run (see its own header comment). If those flags
# are missing entirely (provision.env predates this feature, or setup never finished a run),
# this script asks before touching a project or cluster it finds under the configured name —
# it never assumes.
#
# WHAT GETS DELETED, IN ORDER (reverse of setup-capella.sh's creation order):
#   1. App Endpoint   — always, if found. Uniquely ours by name (CB_ENDPOINT_NAME) even when
#                        the App Service itself is shared with another app.
#   2. App Service    — ONLY if APP_SERVICE_CREATED_BY_SCRIPT=true. If it was reused/shared,
#                        it — and anything else under it — is left completely alone (its
#                        Admin Credential, CIDR allow-list, any other App Endpoint).
#   3. Bucket         — always, if found. Domain-named (CB_BUCKET_NAME), always considered
#                        this demo's own; deleting it also removes its scopes/collections.
#   4. Cluster        — ONLY if CLUSTER_CREATED_BY_SCRIPT=true.
#   5. Project        — ONLY if PROJECT_CREATED_BY_SCRIPT=true.
# The Organization itself is never touched.
#
# TRIGGER: run this ONLY when the user explicitly asks to tear down / delete / remove all the
# backend that was created for this demo or app. Never run it proactively, as part of routine
# setup, or just because setup-capella.sh failed partway (re-running setup-capella.sh is
# idempotent and the right fix for that).
#
# Usage:
#   source provision.env && ./teardown-capella.sh
#   # Prints the exact plan — what will be deleted, what will be left alone and why — then
#   # asks for ONE final y/N confirmation before touching anything.
#   #   -y / --yes   skip the confirmation prompt (e.g. non-interactive use). Still bounded
#   #                by the same provenance checks — it never deletes anything not marked
#   #                as created by this script, prompt or no prompt.
# =============================================================================

set -euo pipefail
trap 'echo "" >&2; echo "❌ teardown failed at line $LINENO: $BASH_COMMAND" >&2' ERR

_script_dir="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "${_script_dir}/setup-capella.sh" ]]; then
  echo "❌ setup-capella.sh not found next to this script (${_script_dir}) — teardown reuses" >&2
  echo "   its config loading and API helpers, so it must live in the same folder." >&2
  exit 1
fi

# Source setup-capella.sh for its config loading (CB_*, provision.env resolution), api() /
# api_or_empty() helpers, logging, and _persist_secret / _read_persisted / _cluster_rows /
# bucket_exists_in_cluster / get_org_id. Guarded at the bottom of that file so its own setup
# flow (main()) does NOT auto-run just from being sourced. _SOURCED_FOR_TEARDOWN also skips
# its one-time Admin Credential password auto-generation, which teardown has no use for.
_SOURCED_FOR_TEARDOWN=true
# shellcheck source=./setup-capella.sh
source "${_script_dir}/setup-capella.sh"

check_deps
validate_config

AUTO_YES=false
for _arg in "$@"; do
  case "$_arg" in
    -y|--yes) AUTO_YES=true ;;
  esac
done

# Clears one persisted var back to "" (not "false") — used after a successful delete so a
# later setup-capella.sh run starts from "unknown / not yet recorded" for that resource,
# rather than a stale "true"/ID pointing at something that no longer exists.
_clear_persisted() {
  _persist_secret "$1" ""
}

echo ""
echo "=================================================="
echo "  Capella Backend Teardown"
echo "  (deletes ONLY what setup-capella.sh created for this demo)"
echo "=================================================="
echo ""

org_id=$(get_org_id)
if [[ -z "$org_id" || "$org_id" == "null" ]]; then
  echo "❌ Could not resolve org ID."; exit 1
fi

# --- Resolve which project/cluster/bucket/app-service we're actually talking about --------
# Prefer the IDs setup-capella.sh itself resolved and persisted on its last run — this stays
# correct even in the free-tier org-wide-redirect case, where the project/cluster actually
# used may not be named CB_PROJECT_NAME/CB_CLUSTER_NAME at all. Fall back to a plain by-name
# lookup only when no persisted ID is available.
project_id="$(_read_persisted RESOLVED_PROJECT_ID "")"
cluster_id="$(_read_persisted RESOLVED_CLUSTER_ID "")"
bucket_id="$(_read_persisted RESOLVED_BUCKET_ID "")"
app_service_id="$(_read_persisted RESOLVED_APP_SERVICE_ID "")"
project_created="$(_read_persisted PROJECT_CREATED_BY_SCRIPT "")"
cluster_created="$(_read_persisted CLUSTER_CREATED_BY_SCRIPT "")"
app_service_created="$(_read_persisted APP_SERVICE_CREATED_BY_SCRIPT "")"

if [[ -z "$project_id" ]]; then
  log "⚠️  No RESOLVED_PROJECT_ID in provision.env — falling back to looking up project '$CB_PROJECT_NAME' by name."
  project_id=$(api_or_empty GET "/organizations/${org_id}/projects" \
    | jq -r --arg n "$CB_PROJECT_NAME" '.data[]? | select(.name==$n) | .id' | head -1)
fi
if [[ -z "$project_id" || "$project_id" == "null" ]]; then
  echo "ℹ️  No project found (by saved ID, or by name '$CB_PROJECT_NAME') — nothing to tear down. Exiting."
  exit 0
fi

if [[ -z "$cluster_id" ]]; then
  log "⚠️  No RESOLVED_CLUSTER_ID in provision.env — falling back to looking up cluster '$CB_CLUSTER_NAME' by name."
  _clist=$(api_or_empty GET "/organizations/${org_id}/projects/${project_id}/clusters")
  _crows="$(_cluster_rows "$_clist")"
  cluster_id=$(printf '%s\n' "$_crows" | awk -F'\t' -v n="$CB_CLUSTER_NAME" '$2==n{print $1; exit}')
fi

if [[ -n "$cluster_id" && "$cluster_id" != "null" ]]; then
  if [[ -z "$bucket_id" ]]; then
    bucket_id=$(bucket_exists_in_cluster "$org_id" "$project_id" "$cluster_id" "$CB_BUCKET_NAME")
  fi
  if [[ -z "$app_service_id" ]]; then
    _svc_list=$(api_or_empty GET "/organizations/${org_id}/appservices")
    app_service_id=$(echo "$_svc_list" | jq -r --arg cid "$cluster_id" '.data[]? | select(.clusterId==$cid) | .id' | head -1)
  fi
fi

endpoint_found=false
if [[ -n "${app_service_id:-}" && "$app_service_id" != "null" ]]; then
  ep_path="/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}/appEndpoints"
  ep_list=$(api_or_empty GET "$ep_path")
  ep_name=$(echo "$ep_list" | jq -r --arg n "$CB_ENDPOINT_NAME" '.data[]? | select(.name==$n) | .name' | head -1)
  [[ -n "$ep_name" && "$ep_name" != "null" ]] && endpoint_found=true
fi

# --- Decide the action for each of Project/Cluster: delete / leave-alone / ask ------------
# "" (never recorded) is genuinely different from "false" (recorded reused) — only the
# unknown case prompts; a recorded "false" is left alone silently, same as "true" deletes
# silently. This is the one interactive step in this script, and only fires when provenance
# truly isn't known.
_decide() {
  local label="$1" created_flag="$2" found_name="$3"
  if [[ "$created_flag" == "true" ]]; then
    echo "delete"
  elif [[ "$created_flag" == "false" ]]; then
    echo "leave"
  else
    echo "" >&2
    echo "❓ Found a $label named '$found_name', but provision.env has no record of whether" >&2
    echo "   setup-capella.sh created it or it already existed before that first run." >&2
    if [[ "$AUTO_YES" == "true" ]]; then
      echo "   -y/--yes given with no provenance on record — defaulting to LEAVE ALONE (safer)." >&2
      echo "leave"
      return
    fi
    read -r -p "   Delete this $label as part of teardown? [y/N] " _ans
    if [[ "$_ans" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "delete"
    else
      echo "leave"
    fi
  fi
}

project_action="leave"
cluster_action="leave"
if [[ -n "$project_id" && "$project_id" != "null" ]]; then
  project_action="$(_decide "Project" "$project_created" "$CB_PROJECT_NAME")"
fi
if [[ -n "${cluster_id:-}" && "$cluster_id" != "null" ]]; then
  cluster_action="$(_decide "Cluster" "$cluster_created" "$CB_CLUSTER_NAME")"
fi
# A manual "delete"/"leave" answer above is itself a statement of provenance for next
# time — record it so a re-run (or an interrupted teardown resumed later) doesn't ask again.
# Written as explicit ifs (not "[[ cond ]] && cmd") to stay unambiguous under set -e.
if [[ -z "$project_created" ]]; then
  if [[ "$project_action" == "delete" ]]; then
    _mark_provenance_if_unset PROJECT_CREATED_BY_SCRIPT true
  else
    _mark_provenance_if_unset PROJECT_CREATED_BY_SCRIPT false
  fi
fi
if [[ -z "$cluster_created" ]]; then
  if [[ "$cluster_action" == "delete" ]]; then
    _mark_provenance_if_unset CLUSTER_CREATED_BY_SCRIPT true
  else
    _mark_provenance_if_unset CLUSTER_CREATED_BY_SCRIPT false
  fi
fi

# --- Print the plan and get ONE confirmation before touching anything ---------------------
echo ""
echo "Plan:"
if [[ "$endpoint_found" == "true" ]]; then
  echo "  App Endpoint '$CB_ENDPOINT_NAME'         → DELETE"
else
  echo "  App Endpoint '$CB_ENDPOINT_NAME'         → not found, nothing to do"
fi
if [[ -n "${app_service_id:-}" && "$app_service_id" != "null" ]]; then
  if [[ "$app_service_created" == "true" ]]; then
    echo "  App Service ($app_service_id)  → DELETE (created by this script)"
  else
    echo "  App Service ($app_service_id)  → LEAVE ALONE (reused/shared — not created by this script)"
  fi
else
  echo "  App Service                          → not found, nothing to do"
fi
if [[ -n "${bucket_id:-}" && "$bucket_id" != "null" ]]; then
  echo "  Bucket '$CB_BUCKET_NAME' ($bucket_id)  → DELETE"
else
  echo "  Bucket '$CB_BUCKET_NAME'                → not found, nothing to do"
fi
if [[ -n "${cluster_id:-}" && "$cluster_id" != "null" ]]; then
  if [[ "$cluster_action" == "delete" ]]; then
    echo "  Cluster '$CB_CLUSTER_NAME' ($cluster_id) → DELETE"
  else
    echo "  Cluster '$CB_CLUSTER_NAME' ($cluster_id) → LEAVE ALONE"
  fi
else
  echo "  Cluster '$CB_CLUSTER_NAME'               → not found, nothing to do"
fi
if [[ "$project_action" == "delete" ]]; then
  echo "  Project '$CB_PROJECT_NAME' ($project_id) → DELETE"
else
  echo "  Project '$CB_PROJECT_NAME' ($project_id) → LEAVE ALONE"
fi
echo ""

if [[ "$AUTO_YES" != "true" ]]; then
  read -r -p "Proceed with this plan? [y/N] " _confirm
  if [[ ! "$_confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "Cancelled — nothing was deleted."
    exit 0
  fi
fi

# --- Execute, in order: App Endpoint → App Service → Bucket → Cluster → Project -----------

if [[ "$endpoint_found" == "true" ]]; then
  echo ""
  echo "🔗 Deleting App Endpoint '$CB_ENDPOINT_NAME'..."
  api_or_empty DELETE "${ep_path}/${CB_ENDPOINT_NAME}" > /dev/null
  echo "   ✅ App Endpoint deleted."
fi

if [[ -n "${app_service_id:-}" && "$app_service_id" != "null" && "$app_service_created" == "true" ]]; then
  echo ""
  echo "🔧 Deleting App Service ($app_service_id)..."
  if [[ "$FREE_TIER" == "true" ]]; then
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/freeTier/${app_service_id}" > /dev/null
  else
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/appservices/${app_service_id}" > /dev/null
  fi
  echo "   ✅ App Service deleted (cascades its Admin Credential and CIDR allow-list)."
  _clear_persisted APP_SERVICE_CREATED_BY_SCRIPT
  _clear_persisted RESOLVED_APP_SERVICE_ID
elif [[ -n "${app_service_id:-}" && "$app_service_id" != "null" ]]; then
  echo ""
  echo "🔧 Leaving App Service ($app_service_id) alone — reused/shared, not created by this script."
fi

if [[ -n "${bucket_id:-}" && "$bucket_id" != "null" && -n "${cluster_id:-}" && "$cluster_id" != "null" ]]; then
  echo ""
  echo "🪣  Deleting bucket '$CB_BUCKET_NAME' ($bucket_id)..."
  if [[ "$FREE_TIER" == "true" ]]; then
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets/freeTier/${bucket_id}" > /dev/null
  else
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}/buckets/${bucket_id}" > /dev/null
  fi
  echo "   ✅ Bucket deleted (its scopes and collections go with it)."
  _clear_persisted RESOLVED_BUCKET_ID
fi

if [[ -n "${cluster_id:-}" && "$cluster_id" != "null" && "$cluster_action" == "delete" ]]; then
  echo ""
  echo "☁️  Deleting cluster '$CB_CLUSTER_NAME' ($cluster_id)..."
  if [[ "$FREE_TIER" == "true" ]]; then
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/freeTier/${cluster_id}" > /dev/null
  else
    api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}/clusters/${cluster_id}" > /dev/null
  fi
  echo "   ✅ Cluster deleted."
  _clear_persisted CLUSTER_CREATED_BY_SCRIPT
  _clear_persisted RESOLVED_CLUSTER_ID
elif [[ -n "${cluster_id:-}" && "$cluster_id" != "null" ]]; then
  echo ""
  echo "☁️  Leaving cluster '$CB_CLUSTER_NAME' ($cluster_id) alone."
fi

if [[ "$project_action" == "delete" ]]; then
  echo ""
  echo "📁 Deleting project '$CB_PROJECT_NAME' ($project_id)..."
  api_or_empty DELETE "/organizations/${org_id}/projects/${project_id}" > /dev/null
  echo "   ✅ Project deleted."
  _clear_persisted PROJECT_CREATED_BY_SCRIPT
  _clear_persisted RESOLVED_PROJECT_ID
else
  echo ""
  echo "📁 Leaving project '$CB_PROJECT_NAME' ($project_id) alone."
fi

echo ""
echo "=================================================="
echo " Teardown complete."
echo "=================================================="
