# Capella setup (managed cloud)

Collect the values the MCP server needs from a Couchbase Capella cluster.

## 1. Connection string

Capella UI → your cluster → **Connect** → copy the **Connection String**. It looks like:

```
couchbases://cb.<cluster-id>.cloud.couchbase.com
```

**Always `couchbases://` (with the `s`).** Capella requires TLS; plain `couchbase://` is rejected. → `CB_CONNECTION_STRING`.

## 2. Cluster Access credentials

These are **separate from your Capella UI login** (the email/password you sign in with).

UI → cluster → **Settings → Cluster Access** → **Create Access**. (The **Connect** page can also surface these, but **Settings → Cluster Access** is the direct path for SDK/MCP credential setup.)

- Set a username → this becomes `CB_USERNAME`.
- **Password** → `CB_PASSWORD`. Two cases:
  - **Auto-generated** (you click **Auto-generate password**): copy/save it immediately — it's shown only once and can't be retrieved afterward.
  - **You type your own**: you already know it, so there's nothing extra to save.
  - Passwords are **case-sensitive** either way.
- **Access level — Basic (all tiers, the default for MCP):** choose **Read**, **Write**, or **Read & Write**, scoped to a **bucket** → **scope** (or **All Scopes**) → **collection** (or **All Collections**); use **Add Another Selection** to grant more. For a read-only MCP setup give **Read**; add **Write** only if the agent should modify data.
- **Advanced (optional, paid plans only):** Advanced Access Credentials assign role-based, fine-grained privileges (`data_reader`, `query_select`, `data_writer`, `query_insert/update/delete`, …). These require a paid plan — they're **not available on free tier**, and the Basic access above is sufficient for MCP. Only reach for this once you've confirmed the user is on a paid plan.
- Cluster Access credentials are **cluster-scoped** (one credential set per cluster, applied to the buckets/scopes/collections you grant).

## 3. Allowed IP list

Capella **blocks all connections by default**. UI → cluster → **Settings → Allowed IP Addresses**:

- Click **Add Allowed IP** → **Add Current IP Address** (or paste a CIDR in **Allowed IP / CIDR Block**).
- Find your public IP if needed: `curl -s https://api.ipify.org`.
- **Allow Access from Anywhere** (`0.0.0.0/0`) allows any IP — **development only, never production**, and remove it afterward.

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
- **Auth failures** usually mean the UI login was used instead of a Cluster Access credential, or a case-mismatched password.
- Free-tier clusters work fine for this (1 cluster, up to 2 buckets, ~1 GB, no expiry).
