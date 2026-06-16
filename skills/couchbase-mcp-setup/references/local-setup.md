# Local Couchbase Server setup

Collect the values from a Couchbase Server running on your machine. Local clusters use plain `couchbase://` (no TLS).

## Already have a local cluster?

If Couchbase Server is already running (e.g. a `couchbase/server` Docker container), use:

```
CB_CONNECTION_STRING = couchbase://localhost      # or couchbase://127.0.0.1
CB_USERNAME          = Administrator              # or a user you created
CB_PASSWORD          = <your password>
```

Open the Web Console at `http://localhost:8091` to confirm the cluster and bucket exist.

## Quick start with Docker

```bash
docker run -d --name couchbase \
  -p 8091-8097:8091-8097 -p 11210:11210 -p 11207:11207 \
  couchbase/server:enterprise
```

Then:

1. Open `http://localhost:8091` → **Setup New Cluster** → set the admin username (`Administrator`) and a password.
2. Load sample data: **Settings → Sample Buckets → `travel-sample` → Load Sample Data** (or via REST: `curl -u Administrator:<pw> -X POST http://localhost:8091/sampleBuckets/install -d '["travel-sample"]'`).

## Connecting the MCP server

- MCP server running **directly on the host** (`uvx`): use `couchbase://localhost`.
- MCP server running **inside Docker**: use `couchbase://host.docker.internal` so the container can reach the host's cluster (`localhost` would point at the container itself).

## Least-privilege user (optional)

Instead of the `Administrator` account, create a dedicated user in **Security → Users → Add User** with read-only roles (Data Reader + Query Select) scoped to the bucket, and use those credentials. This pairs with `CB_MCP_READ_ONLY_QUERY_MODE=true` for two layers of safety.
