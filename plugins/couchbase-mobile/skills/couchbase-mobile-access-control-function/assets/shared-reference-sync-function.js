/**
 * shared-reference-sync-function.js
 * Access Control Function (a.k.a. sync function) — SHARED READ-ONLY pattern.
 *
 * Deployment: Capella App Services (NOT self-managed Sync Gateway).
 *   Role references do NOT take a "role:" prefix here (unlike self-managed Sync Gateway).
 *
 * Model:
 *   - Documents are routed to the public channel "!", which every authenticated
 *     user automatically receives (read-only shared reference data).
 *   - Only admins can create, edit, or delete.
 *
 * ADAPT:
 *   - Replace "resource" with your document type.
 *   - Add/adjust required-field and immutable-field validation for your schema.
 */
function (doc, oldDoc) {
  // ADAPT: document type
  var DOC_TYPE = "resource";

  if (doc.type == DOC_TYPE || (doc._deleted && oldDoc && oldDoc.type == DOC_TYPE)) {

    // Only admins may create, edit, or delete — checked first, before any
    // validation, so a non-admin is rejected immediately without exposing
    // required-field/immutable-field validation behavior.
    requireRole("admin");

    // Deletes: tombstones don't need field validation and inherit the public
    // channel automatically.
    if (doc._deleted) {
      return;
    }

    // Required-field validation (ADAPT to your schema)
    if (!doc.title) throw ({ forbidden: "title is required" });

    // Immutable fields on update
    if (oldDoc && !oldDoc._deleted) {
      if (doc.type !== oldDoc.type) throw ({ forbidden: "type cannot be changed" });
    }

    // Route to the public channel — all authenticated users receive it (read-only).
    channel("!");
  }
}
