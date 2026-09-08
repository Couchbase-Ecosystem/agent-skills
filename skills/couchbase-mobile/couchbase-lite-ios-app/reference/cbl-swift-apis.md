## CBL Swift SDK — Key APIs

### Open Database
```swift
let database = try Database(name: "MyAppDB")
// Always use a named scope — never "_default"
let collection = try database.createCollection(name: "tasks", scope: "fieldops")
```

### CRUD
```swift
// Create
let doc = MutableDocument(id: UUID().uuidString)
doc.setValue("task", forKey: "type")
doc.setValue("Fix leak", forKey: "title")
try collection.save(document: doc)

// Read
let doc = try collection.document(id: docId)
let title = doc?.string(forKey: "title")

// Update
let mutable = doc.toMutable()
mutable.setValue("done", forKey: "status")
try collection.save(document: mutable)

// Delete (creates tombstone — syncs as deletion)
try collection.delete(document: doc)
```

### Indexes (query performance)

Create a **value index** on fields you filter or sort on frequently — without one, live queries do a full collection scan and get slow as data grows. Create indexes once, right after opening the collection.

```swift
// Index the fields used in WHERE / ORDER BY (e.g. per-user task lists)
let idx = ValueIndexConfiguration(["assignee", "status"])
try collection.createIndex(withName: "taskAssigneeStatus", config: idx)
```

Rule of thumb: any field in a `WHERE`, `ORDER BY`, or `MATCH` clause should be indexed (value index for equality/range/sort, `FullTextIndexConfiguration` for `MATCH`). Always bind user-supplied values with `Parameters` (see Full-Text Search below) rather than interpolating them into the query string.

### Live Query (keeps UI in sync automatically)

> ⚠️ `change.results` is `ResultSet?`, NOT `[Any]?`. Never use `change.results ?? []` — it causes a compile error. Always use `if let results = change.results`.

```swift
// Query uses named scope: scopeName.collectionName
let query = try database.createQuery(
    "SELECT META().id AS id, * FROM fieldops.tasks WHERE type = 'task' ORDER BY title ASC"
)
let token = query.addChangeListener { [weak self] change in
    guard let self else { return }
    if let error = change.error {
        self.errorMessage = error.localizedDescription
        return
    }
    var items: [MyModel] = []
    // CORRECT: if let, not ?? []
    if let results = change.results {
        for row in results {
            let docId = row.string(forKey: "id") ?? ""
            // `SELECT *` projects the document under the COLLECTION NAME ("tasks"), so unwrap
            // dictionary(forKey: "tasks") — NOT dictionary(at: 1), which returns the
            // { "tasks": { …fields… } } wrapper. (Matches the reference app + the Android skill.)
            if let dict = row.dictionary(forKey: "tasks")?.toDictionary(),
               let item = MyModel(id: docId, dictionary: dict) {
                items.append(item)
            }
        }
    }
    self.items = items
}
try query.execute()

// WRONG — compile error ("Cannot convert value of type '[Any]' to ResultSet"):
// for row in change.results ?? [] { ... }
```

### Replicator Setup
```swift
let target = URLEndpoint(url: URL(string: "wss://xxx.apps.cloud.couchbase.com:4984/endpoint")!)
// Pass collections to the initializer. Each is wrapped via CollectionConfiguration(collection:).
// The old ReplicatorConfiguration(target:) + config.addCollection(...) forms were REMOVED in 4.0.
let collConfigs = [
    // Pass the Collection OBJECTS you created (what your DatabaseManager exposes), not name strings.
    CollectionConfiguration(collection: tasksCollection),
    CollectionConfiguration(collection: resourcesCollection),
]
var config = ReplicatorConfiguration(collections: collConfigs, target: target)
config.replicatorType = .pushAndPull
config.continuous = true
config.authenticator = BasicAuthenticator(username: username, password: password)
let replicator = Replicator(config: config)
replicator.start()
```

### Full-Text Search
```swift
// Create index once
let fts = FullTextIndexConfiguration(["title", "body"])
try collection.createIndex(withName: "myFTS", config: fts)

// Query
let q = try database.createQuery(
    "SELECT META().id, * FROM myapp.items WHERE MATCH(myFTS, $term)"
)
let params = Parameters()
params.setString("fire safety", forName: "term")
q.parameters = params
```

### Blobs (file attachments)
```swift
// Attach a blob to a document
let imageData = ... // Data
let blob = Blob(contentType: "image/jpeg", data: imageData)
doc.setValue(blob, forKey: "photo")
try collection.save(document: doc)

// Read blob
let blob = doc?.blob(forKey: "photo")
let data = blob?.content
```
> Blobs are always attached to a document — they cannot be standalone.

---

