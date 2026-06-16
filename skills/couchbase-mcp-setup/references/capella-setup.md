# Capella setup (managed cloud)

Collect the values the MCP server needs from a Couchbase Capella cluster.

## 1. Connection string

Capella UI → your cluster → **Connect** → copy the **Connection String**. It looks like:

```
couchbases://cb.<cluster-id>.cloud.couchbase.com
```

**Always `couchbases://` (with the `s`).** Capella requires TLS; plain `couchbase://` is rejected. → `CB_CONNECTION_STRING`.

## 2. Database Access credentials

These are **separate from your Capella UI login** (the email/password you sign in with).

UI → cluster → **Connect → Database Access** (or **Settings → Database Access**) → **Create Database Credentials**:

- Set a username and password → these become `CB_USERNAME` / `CB_PASSWORD`.
- The password is **shown once** — save it immediately. Passwords are **case-sensitive**.
- **Grant least privilege.** For a read-only MCP setup, give the user **Read** access (data reads + `query_select`) scoped to the target bucket. Only add write privileges (`data_writer`, `query_insert/update/delete`) if the user intends the agent to modify data.
- Database credentials are **cluster-scoped** (one credential set per cluster, applied to the buckets/scopes you grant).

## 3. Allowed IP list

Capella **blocks all connections by default**. UI → cluster → **Connect → Allowed IP Addresses**:

- Click **Add Allowed IP** → **Add Current IP Address** (or paste a CIDR).
- Find your public IP if needed: `curl -s https://api.ipify.org`.
- `0.0.0.0/0` allows any IP — **development only, never production**, and remove it afterward.

If you skip this, connections will simply time out.

## 4. A bucket with data

The server connects at the cluster level — there is no bucket env var — but you need at least one bucket with data to query. To load sample data: UI → **Data Tools → Buckets → Import Sample Data → `travel-sample` → Import**. Bucket names passed to tools are case-sensitive.

## Result

```
CB_CONNECTION_STRING = couchbases://cb.<cluster-id>.cloud.couchbase.com
CB_USERNAME          = <database credential username>
CB_PASSWORD          = <database credential password>
```

## Gotchas

- **Timeouts** almost always mean a missing Allowed-IP entry or a `couchbase://` (non-TLS) scheme.
- **Auth failures** usually mean the UI login was used instead of a Database Access credential, or a case-mismatched password.
- Free-tier clusters work fine for this (1 cluster, up to 2 buckets, ~1 GB, no expiry).
