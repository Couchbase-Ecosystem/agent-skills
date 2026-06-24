# ALTER BUCKET

The ALTER BUCKET statement enables you to update an existing bucket's configuration.

## Purpose

Use the ALTER BUCKET statement to modify the configuration of a bucket in your Couchbase cluster.
You can update only a limited set of bucket settings.
You cannot change its core properties such as the bucket name and type.
For more information, see the [Syntax](#syntax) section.

## RBAC Privileges

Only administrators with the following roles can execute the ALTER BUCKET statement:

* Full Admin
* Cluster Admin
* Bucket Admin (if privileges are extended to the specific bucket or all buckets on the cluster)

For more information about roles and privileges, see [Roles](learn:security/roles.adoc).

## Syntax

```ebnf
alter-bucket ::= 'ALTER' ( 'BUCKET' | 'DATABASE' ) name ( 'WITH' with-fields )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/alter-bucket.png)

The `BUCKET` and `DATABASE` keywords are synonyms.
You can use either of them.

* **name**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that represents the name of the bucket that you want to update.
* **with-fields**\
(Optional)
A JSON object containing a list of name-value pairs that specify additional options for the bucket.
For a list of valid fields names and values, see [Bucket Parameter Groups](rest-api:rest-bucket-create.adoc#parameter-groups) in the REST API documentation.

**📌 NOTE**\
You cannot alter the following fields of a bucket: `bucketType`, `storageBackend`, `replicaIndex`, and `conflictResolutionType`.

## Example

**Alter a bucket and update its memory quota, maximum TTL, and durability level**

```sqlpp
ALTER BUCKET `student-records`
WITH {
    "ramQuota": 256,
    "maxTTL": 86400,
    "durabilityMinLevel": "majority"
};
```

## Related Links

* For an overview of buckets, see [Buckets](learn:buckets-memory-and-storage/buckets.adoc).
* For step-by-step procedures for bucket management, see [Manage Buckets](manage:manage-buckets/bucket-management-overview.adoc).
* For managing buckets with the REST API, see [Buckets API](rest-api:rest-bucket-intro.adoc).
