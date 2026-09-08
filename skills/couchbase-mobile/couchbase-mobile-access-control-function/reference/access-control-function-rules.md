## Access Control Function Rules (CRITICAL)

1. **`requireRole()` does NOT use the `role:` prefix in App Services**: Use `requireRole("admin")` NOT `requireRole("role:admin")`. The `role:` prefix does not apply in App Services ACFs and will never match.
2. **`access()` also does NOT use the `role:` prefix in App Services ACFs**: `access("role:admin", channelName)` is WRONG — it tries to grant a user literally named `"role:admin"` (which doesn't exist). In App Services ACFs, `access()` only accepts usernames, not role names. **To grant an admin user access to the "admin" channel, use `admin_channels` in the Admin REST API at user creation — NOT an `access()` call in the ACF.** `access("role:admin", ...)` syntax is Sync Gateway-only and does not work in App Services.
3. **Handle deletes correctly**: Check `doc._deleted && oldDoc && oldDoc.type == "your_type"`. Do NOT call `channel()` on delete — the tombstone inherits channels automatically. Just do access checks and `return`.
4. **Use oldDoc for stable values**: On update/delete, read `assignee`, `owner`, `type` from `oldDoc`, not `doc`. `doc` properties are untrusted on update.
5. **Immutable fields**: Enforce with `if (doc.field !== oldDoc.field) throw({forbidden: "..."})`. Fields that should typically be immutable: `type`, `owner`, `assignee`, `createdAt`, any business key.
6. **Partial updates (field workers)**: To allow updates to only certain fields, check every other field against `oldDoc` and throw forbidden if changed. This enforces field-level write restrictions.
7. **Channel name consistency**: The string passed to `channel()` must exactly match the string used in `requireAccess()`. If you route to `channel(assignee)` then `requireAccess` must list the assignee's username, not a prefixed variant.
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

