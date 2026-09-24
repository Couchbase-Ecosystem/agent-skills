## Access Control Function Rules (CRITICAL)

1. **`requireRole()` does NOT use the `role:` prefix in App Services** (unlike self-managed Sync Gateway). Use `requireRole("admin")`, NOT `requireRole("role:admin")`. *(Reverted 2026-09-24 — the 2026-09-22 "correction" claiming the prefix is required was itself wrong. Re-verified against Couchbase's own `requireRole()` docs, whose own usage examples show the bare form, and against a live Capella App Services failure: the prefixed form was rejected with `sg missing role` for a user who genuinely holds the role, and dropping the prefix fixed it.)*
2. **This skill grants admin channel access via `admin_channels` in the Admin REST API at role creation, not via a per-document `access()` call in the ACF — as a design choice, not a proven platform limitation.** An earlier version of this rule claimed `access(["someone", "role:admin"], channelName)` can't grant the `admin` role anything at all on App Services; that was never actually tested against a live endpoint, and Couchbase's own `access()` reference docs describe the `role:` prefix as valid with no Capella-specific exception noted. Treat `access()` + a role principal on App Services as unconfirmed rather than broken -- but this skill still grants statically here regardless, since the static grant only needs to happen once per role, not on every write.
3. **Handle deletes correctly**: Check `doc._deleted && oldDoc && oldDoc.type == "your_type"`. Do NOT call `channel()` on delete — the tombstone inherits channels automatically. Just do access checks and `return`.
4. **Use oldDoc for stable values**: On update/delete, read `assignee`, `owner`, `type` from `oldDoc`, not `doc`. `doc` properties are untrusted on update.
5. **Immutable fields**: Enforce with `if (doc.field !== oldDoc.field) throw({forbidden: "..."})`. Fields that should typically be immutable: `type`, `owner`, `assignee`, `createdAt`, any business key.
6. **Partial updates (field workers)**: To allow updates to only certain fields, check every other field against `oldDoc` and throw forbidden if changed. This enforces field-level write restrictions.
7. **`requireAccess()` uses OR, not AND — and it does not apply to every document type.** `requireAccess([a, b, ...])` passes if the user has access to **any one** of the listed channels, not all of them. (Confirmed against the Sync Gateway sync function API docs: it rejects the write unless the user has access to at least one of the given channels.) This is what makes `requireAccess([assignee, ADMIN_CHANNEL])` work as a single gate for two different principals: a regular user passes via their own `assignee` channel; an admin passes via the shared `ADMIN_CHANNEL` — neither needs both, and a document is not required to have been routed identically for each. This rule only matters for models that call `requireAccess()` at all — the shared-reference pattern, for instance, has none: writes are gated by `requireRole()` alone, and reads come for free from the public `"!"` channel every authenticated user already has. Where a model does use `requireAccess()`, keep its channel list consistent with the `channel()` calls in the same function — every channel you authorize against should be one you actually route the document into, or the writer risks not being able to read back what they just wrote.
8. **access() is cumulative**: Supplements (doesn't replace) static channel grants in App Services.
9. **requireAccess() and wildcards**: `requireAccess()` does NOT recognise wildcard (`*`) grants — it only honours *explicit named-channel* grants. A principal granted only `*` will **fail** `requireAccess("someChannel")` even though `*` lets them read/replicate every channel. Implication: if you gate with `requireAccess()` on a named channel, an admin who has only `*` will be rejected. Either grant that admin an explicit named channel too (named-admin-channel design), or authorize the admin path with `requireRole()` instead of `requireAccess()` (wrap: `try { requireAccess([assignee]); } catch (e) { requireRole("admin"); }`). Docs: https://docs.couchbase.com/sync-gateway/current/sync-function-api-require-access-cmd.html

### Access Control Function — File generation rules

**File naming:** `sync-functions/<collection>-sync-function.js` — one file per collection.
```
COLLECTIONS='todo/todos'       → sync-functions/todos-sync-function.js
COLLECTIONS='fieldops/tasks'   → sync-functions/tasks-sync-function.js
```

**File format:** Write the function as a plain `function(doc, oldDoc){...}` with a comment header. The script strips block comments and wraps in `()` before uploading, because `eval("function(doc,oldDoc){...}")` at statement level evaluates to `undefined` — only `eval("(function(doc,oldDoc){...})")` evaluates to a function.

> ⚠️ PUT `/accessControlFunction` — correct usage (read the OpenAPI spec carefully):
> - **Content-Type: `application/javascript`** — NOT `application/json`, NOT `text/plain`
> - **Body: raw JavaScript function text** — NOT JSON-encoded, NOT wrapped in an object
> - **Strip ALL comments** before sending — non-ASCII characters in comments (e.g. em dashes `—`) cause the JS parser to fail
>
> ```bash
> # Strip comments (block and inline)
> fn_clean=$(echo "$fn_content" \
>   | sed '/^[[:space:]]*\/\*\*/,/\*\//d' \
>   | sed 's|[[:space:]]*//.*$||g' \
>   | sed '/^[[:space:]]*$/d')
>
> # Send as application/javascript with raw function text
> curl -s -X PUT ".../accessControlFunction" \
>   -H "Authorization: Bearer ${CB_API_KEY}" \
>   -H "Content-Type: application/javascript" \
>   --data-binary "$fn_clean"
> ```
> Do NOT use `api()` for this call — it forces `Content-Type: application/json` which causes 400 errors.

---

