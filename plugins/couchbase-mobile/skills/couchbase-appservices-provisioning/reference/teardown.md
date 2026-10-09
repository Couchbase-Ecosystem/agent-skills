## Tearing down a demo backend

`assets/teardown-capella.sh` deletes the Capella backend resources a given `setup-capella.sh` run actually created — nothing more.

### When to use this

**Only when the user explicitly asks** to tear down, delete, or remove the backend that was created for a demo or app — e.g. "tear down the Capella backend for this", "delete everything we created for this demo". Never run it proactively, never suggest it unprompted, and never run it just because a `setup-capella.sh` run failed partway through (that script is idempotent — re-running it is the right fix for a partial/failed setup, not tearing down and starting over).

### Why provenance, not just "does it exist"

Capella resources can genuinely be shared. A cluster can already hold another app's demo (Capella allows only 1 free-tier cluster per org, so `setup-capella.sh` sometimes reuses an existing one after asking — see `backend-setup.md`). A cluster can only ever have one App Service, so a cluster shared across two demos also shares its App Service. Deleting a shared Cluster, Project, or App Service out from under another app would be destructive and surprising — so teardown never does it based on name matching alone.

Instead, `setup-capella.sh` now records **provenance** for the three resources that can genuinely be pre-existing/shared — `PROJECT_CREATED_BY_SCRIPT`, `CLUSTER_CREATED_BY_SCRIPT`, `APP_SERVICE_CREATED_BY_SCRIPT` — in `provision.env`, every time it runs:
- Set to `true` the moment it actually creates the resource.
- Set to `false` the first time it finds the resource already existing (and only the first time — this is **sticky**: once `true`, a later re-run that simply finds the resource already there never flips it back to `false`).

The Bucket and App Endpoint get no provenance flag — they're domain-named (`CB_BUCKET_NAME`, `CB_ENDPOINT_NAME`), so they're always considered this demo's own, and deleting them never risks another app's resources.

`setup-capella.sh` also persists the concrete IDs it resolved on its last run (`RESOLVED_PROJECT_ID`, `RESOLVED_CLUSTER_ID`, `RESOLVED_BUCKET_ID`, `RESOLVED_APP_SERVICE_ID`), so teardown uses the exact resources setup last touched rather than re-deriving them by name — this matters especially for the free-tier org-wide-redirect case, where the project/cluster actually in use may not be named `CB_PROJECT_NAME`/`CB_CLUSTER_NAME` at all (see `backend-setup.md`'s note on that redirect).

### What it deletes, and in what order

Reverse of creation order:

1. **App Endpoint** — always, if found. It's uniquely ours by name even when the App Service itself is shared.
2. **App Service** — only if `APP_SERVICE_CREATED_BY_SCRIPT=true`. If reused/shared, it (and its Admin Credential, CIDR allow-list, anything else under it) is left completely alone — teardown has already removed just this app's own App Endpoint from it above.
3. **Bucket** — always, if found (this also removes its scopes/collections).
4. **Cluster** — only if `CLUSTER_CREATED_BY_SCRIPT=true`.
5. **Project** — only if `PROJECT_CREATED_BY_SCRIPT=true`.

The Organization is never touched.

### If provenance isn't recorded

If `provision.env` predates this feature, or `setup-capella.sh` never completed a run, the `*_CREATED_BY_SCRIPT` flags may be blank rather than `true`/`false`. Blank is treated as genuinely unknown — different from a recorded `false` — so for a Project or Cluster found under the configured name with no provenance on record, teardown **asks** before including it in the plan, exactly as it would if you asked it directly: "found a Project/Cluster named X — was this created for this demo, or does it pre-exist?" Whatever you answer is then recorded, so a later run doesn't ask again. Run non-interactively with `-y`/`--yes` and it defaults to leaving an unknown resource alone rather than guessing.

### Running it

```
source provision.env && ./teardown-capella.sh
```

It prints the exact plan — what will be deleted, what will be left alone and why — and asks for **one** final confirmation before touching anything. `-y`/`--yes` skips that confirmation (e.g. for non-interactive use) but is still bounded by the same provenance checks.
