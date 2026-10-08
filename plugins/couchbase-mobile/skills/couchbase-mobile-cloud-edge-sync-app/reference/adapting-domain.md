## Adapting to a New Domain

When a user describes their app, do this:

0. **Name the cast and explain the flow first** (before generating). Map the abstract roles to the domain's real people: **who the app users are** (who signs in, owns records), **who holds the manager/admin role**, **what the record ("task") is**, and the **create → assign → update → observe** flow. Say it in one or two plain sentences and confirm it fits. Example (airline meal ordering): app users = cabin crew; manager = head of cabin crew (purser); record = a meal-prep order ("prepare 40 veg meals on BA123"); purser creates & assigns, each crew member updates their own, purser sees all. See the recipe's "Domain parameterization" table.
1. **Infer the data model from the domain** — only ask clarifying questions if genuinely ambiguous
2. **Choose a named scope** for the app (never `_default`) — see `couchbase-mobile-concepts-patterns`
3. **Identify the channel pattern** (per-user, admin-assigns, team, or public reference data) — see `couchbase-mobile-concepts-patterns`
4. **Write the access control function** using the templates in `couchbase-mobile-access-control-function` — one per collection
5. **Generate Swift models** with `toDictionary()` / `init?(id:dictionary:)` methods — see `couchbase-lite-ios-app`
6. **Generate `AppConfig.swift`** with the correct named scope and collection names — see `couchbase-lite-ios-app`
7. **Adapt DatabaseManager** — update queries to use `scopeName.collectionName`
8. **Adapt views** — rename fields, update forms
9. **Generate the full `.xcodeproj`** as described in `couchbase-lite-ios-app`

