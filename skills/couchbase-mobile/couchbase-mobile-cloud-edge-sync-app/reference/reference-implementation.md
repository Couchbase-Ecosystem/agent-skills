## Reference Implementation

The public **Couchbase Retail Demo** is the reference implementation to point users at:
https://github.com/couchbase-examples/couchbase-lite-retail-demo — a maintained, multi-platform (iOS, Android, React Native, web) offline-first app with cloud sync *and* peer-to-peer sync. Use its `/iOS` app as the worked example for project structure, replication setup, live queries, and UI patterns.

### The one gap to fill: access-control model

The Retail Demo uses a **simple store-isolation** access model — one App User per store, one scope per store, no roles/admin/per-user channels. That is intentional for its use case, but it does **not** demonstrate the comprehensive model many apps need (an admin role that sees everything, per-user private data, shared read-only data, admin-assigns, validation, status-locking).

That comprehensive model is captured **self-contained** in
`couchbase-mobile-access-control-function/reference/example-comprehensive-access-model.md`
so the skill teaches it directly, with no dependency on any private app.

### Provenance (not distributed)

The comprehensive access model above was distilled from an internal example app, **FieldTaskTracker**. That app is **not bundled with this skill and not published** — do not link to it or assume it is reachable. Everything a builder needs is already captured in the reference file cited above; treat FieldTaskTracker purely as the historical source of those patterns.

### How to use these together

- Structure / build settings / replication / P2P / multi-platform → adapt the public **Retail Demo** (see also `couchbase-lite-ios-app/reference/canonical-references.md`).
- Comprehensive users + roles + channels access control → follow `example-comprehensive-access-model.md`.

When building a new app, adapt these references rather than starting from scratch.

---
