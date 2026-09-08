/**
 * admin-assigns-sync-function.js
 * Access Control Function (a.k.a. sync function) — ADMIN-ASSIGNS pattern.
 *
 * Deployment: Capella App Services (NOT self-managed Sync Gateway).
 *   App Services does NOT support the "role:" prefix — use bare role names.
 *   (On self-managed Sync Gateway the "role:" prefix is valid; the bare form
 *    below works on both, so it is the portable choice.)
 *
 * Model:
 *   - Each document is routed to the assignee's private channel (their username).
 *   - Regular users read/update only their own docs; admins see everything.
 *   - Admins create/reassign/delete; regular users cannot.
 *
 * ── "admin" appears as TWO INDEPENDENT identifiers here ──────────────────────
 *   ADMIN_ROLE    = the App Role that may create/reassign/delete (a *principal*).
 *   ADMIN_CHANNEL = the shared channel documents are routed to so admins receive
 *                   them (a *document grouping*).
 *   They share the string "admin" only by convention — rename either freely
 *   (e.g. role "managers", channel "all-tasks"). They do NOT have to match.
 *
 * ── TWO ADMIN DESIGNS (see admin-access-patterns.md) ─────────────────────────
 *   (A) Named admin channel  ← shown below (FieldTaskTracker's approach).
 *       Route docs to ADMIN_CHANNEL and grant the admin role that channel ONCE
 *       via the Admin REST API (admin_channels in collection_access). Do NOT
 *       grant it with access() every run — redundant and expensive.
 *   (B) Star channel: grant the admin role "*" via REST instead. Then admins
 *       RECEIVE all channels with no per-doc routing (reads/replication), so:
 *         • DELETE the `channel(ADMIN_CHANNEL)` line, and
 *         • authorize the admin WRITE path by ROLE, not requireAccess: a "*" grant
 *           does NOT satisfy requireAccess() on a named channel (see Rule 9), so
 *           `requireAccess([assignee])` alone would REJECT the admin. Wrap it:
 *             try { requireAccess([assignee]); } catch (e) { requireRole(ADMIN_ROLE); }
 *
 * ADAPT:
 *   - Replace "task" with your document type.
 *   - Replace "assignee" with your ownership field if different.
 *   - Adjust required-field / immutable-field validation for your schema.
 */
function (doc, oldDoc) {
  // ADAPT: document type, and the two independent "admin" identifiers
  var DOC_TYPE      = "task";
  var ADMIN_ROLE    = "admin";   // principal: who may create/reassign/delete
  var ADMIN_CHANNEL = "admin";   // channel: where docs are routed for admins (design A only)

  if (doc.type == DOC_TYPE || (doc._deleted && oldDoc && oldDoc.type == DOC_TYPE)) {

    // Read stable identity from oldDoc on update/delete — never trust doc for these
    var assignee = oldDoc ? oldDoc.assignee : doc.assignee;
    if (!assignee) {
      throw ({ forbidden: "assignee is required" });
    }

    // Deletes: admin only. Tombstone inherits channels from the previous revision.
    if (doc._deleted) {
      requireRole(ADMIN_ROLE);
      return;
    }

    // Creates: admin only (admin-assigns) — regular users cannot create.
    if (!oldDoc) {
      requireRole(ADMIN_ROLE);
    }

    // Required-field validation (ADAPT to your schema)
    if (!doc.title)  throw ({ forbidden: "title is required" });
    if (!doc.status) throw ({ forbidden: "status is required" });

    // Immutable fields + state checks on update
    if (oldDoc && !oldDoc._deleted) {
      if (doc.type !== oldDoc.type)         throw ({ forbidden: "type cannot be changed" });
      if (doc.assignee !== oldDoc.assignee) requireRole(ADMIN_ROLE);   // only admin reassigns
      if (oldDoc.status === "closed")       requireRole(ADMIN_ROLE);   // closed = locked for non-admins
    }

    // Routing
    channel(assignee);         // per-user private channel

    // Design A (named admin channel): route to the admin channel so admins receive it.
    // Design B (star "*"): DELETE the next line — admins get all channels via "*".
    channel(ADMIN_CHANNEL);

    // Dynamic, per-user grant — the one correct use of access() here.
    // Do NOT grant the admin role/channel with access() — grant it statically on
    // the role via REST (design A: admin_channels:[ADMIN_CHANNEL]; design B: ["*"]).
    access(assignee, assignee);

    // Read/write gate.
    // Design A (shown): assignee OR the named admin channel — admin has ADMIN_CHANNEL
    // explicitly, so this passes for admins.
    // Design B ("*"): requireAccess([assignee]) alone REJECTS the admin ("*" does not
    // satisfy requireAccess — Rule 9); authorize the admin via role instead:
    //   try { requireAccess([assignee]); } catch (e) { requireRole(ADMIN_ROLE); }
    requireAccess([assignee, ADMIN_CHANNEL]);
  }
}
