#!/usr/bin/env bash
# Provision the LOCAL Couchbase cluster and load travel-sample. Pure REST (curl),
# no couchbase-cli. Idempotent — safe to re-run against an already-initialized
# node (the init steps no-op once done).
set -euo pipefail

CS="${CB_CONNECTION_STRING:-couchbase://couchbase}"
# Extract the bare host: drop the scheme, any multi-node list / path / query,
# optional userinfo (user:pass@), then the port.
host="${CS#*://}"; host="${host%%[,/?]*}"; host="${host##*@}"; host="${host%%:*}"
H="http://${host}:8091"

ADMIN="${CB_ADMIN_USERNAME:-Administrator}"
ADMIN_PW="${CB_ADMIN_PASSWORD:?CB_ADMIN_PASSWORD must be set}"
DBUSER="${CB_USERNAME:-tester}"
DBPASS="${CB_PASSWORD:?CB_PASSWORD must be set}"

echo "[cb-init] initializing cluster at $H"

# 1. Memory quotas + services (no auth on a fresh node; no-op if already set).
curl -sf -X POST "$H/pools/default" \
  -d memoryQuota=1024 -d indexMemoryQuota=512 >/dev/null 2>&1 || true
curl -sf -X POST "$H/node/controller/setupServices" \
  -d 'services=kv,n1ql,index' >/dev/null 2>&1 || true

# 2. Admin credentials (sets the web/admin user).
curl -sf -X POST "$H/settings/web" \
  -d port=8091 -d "username=$ADMIN" -d "password=$ADMIN_PW" >/dev/null 2>&1 || true

# 3. GSI storage mode: plasma (EE) if allowed, else forestdb (CE).
curl -sf -u "$ADMIN:$ADMIN_PW" -X POST "$H/settings/indexes" \
  -d storageMode=plasma >/dev/null 2>&1 \
  || curl -sf -u "$ADMIN:$ADMIN_PW" -X POST "$H/settings/indexes" \
       -d storageMode=forestdb >/dev/null 2>&1 || true

# 4. Least-privilege DB user the MCP server connects as (read-only posture:
#    query + read data + system catalogs for EXPLAIN/ADVISE/list-indexes).
curl -sf -u "$ADMIN:$ADMIN_PW" -X PUT "$H/settings/rbac/users/local/$DBUSER" \
  --data-urlencode "password=$DBPASS" \
  --data-urlencode "roles=data_reader[*],query_select[*],query_system_catalog" \
  >/dev/null 2>&1 || true

# 5. Load travel-sample (no-op / error if already present).
echo "[cb-init] requesting travel-sample sample bucket"
curl -sf -u "$ADMIN:$ADMIN_PW" -X POST "$H/sampleBuckets/install" \
  -d '["travel-sample"]' >/dev/null 2>&1 || true

# 6. Wait until the bucket has loaded its documents (via REST item count, which
#    needs neither indexes nor the query service).
echo "[cb-init] waiting for travel-sample documents to load ..."
for _ in $(seq 1 90); do
  cnt="$(curl -sf -u "$ADMIN:$ADMIN_PW" "$H/pools/default/buckets/travel-sample" 2>/dev/null \
        | jq -r '.basicStats.itemCount // 0' 2>/dev/null || echo 0)"
  if [ "${cnt:-0}" -gt 0 ] 2>/dev/null; then
    echo "[cb-init] travel-sample loaded ($cnt docs)"
    break
  fi
  sleep 4
done
if [ "${cnt:-0}" -le 0 ] 2>/dev/null; then
  echo "[cb-init] travel-sample did not load in time" >&2
  exit 1
fi

# 7. Best-effort: confirm the query service can read it (indexes may still be
#    building — a warning, not a failure).
qcnt="$(curl -sf -u "$DBUSER:$DBPASS" "http://${host}:8093/query/service" \
  --data-urlencode 'statement=SELECT RAW COUNT(*) FROM `travel-sample`.inventory.airport' \
  2>/dev/null | jq -r '.results[0] // 0' 2>/dev/null || echo 0)"
if [ "${qcnt:-0}" -gt 0 ] 2>/dev/null; then
  echo "[cb-init] query service ready (inventory.airport: $qcnt)"
else
  echo "[cb-init] WARN: query service not returning rows yet (indexes may still be building)"
fi

echo "[cb-init] done"
