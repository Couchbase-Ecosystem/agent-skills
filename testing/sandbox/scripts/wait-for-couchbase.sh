#!/usr/bin/env bash
# Block until the cluster's management REST endpoint answers. Derives the host
# and port from CB_CONNECTION_STRING (couchbase://host -> http:8091,
# couchbases://host -> https:18091).
set -euo pipefail

CS="${CB_CONNECTION_STRING:-couchbase://couchbase}"
scheme="${CS%%://*}"
rest="${CS#*://}"
host="${rest%%[,/?]*}"     # first host, drop any path / extra hosts
host="${host%%:*}"         # drop explicit port if present

if [ "$scheme" = "couchbases" ]; then
  base="https://${host}:18091"; insecure="-k"
else
  base="http://${host}:8091"; insecure=""
fi

echo "[wait-for-couchbase] polling ${base}/pools ..."
for _ in $(seq 1 60); do
  # Accept 200 (open/unprovisioned node) OR 401 (Couchbase 8.0 secures /pools and
  # answers 401 once it's up and provisioned) — both prove the management API is
  # reachable. `curl -f` would reject the 401, so inspect the status code directly.
  code="$(curl -s -o /dev/null -w '%{http_code}' $insecure --max-time 5 "${base}/pools" 2>/dev/null || true)"
  case "$code" in
    200|401) echo "[wait-for-couchbase] cluster reachable (HTTP $code)"; exit 0 ;;
  esac
  sleep 3
done

echo "[wait-for-couchbase] ${base} not reachable after timeout" >&2
exit 1
