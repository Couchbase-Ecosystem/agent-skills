# {sqlpp} Error Codes

The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.

## 1xx Codes (shell)

These errors are related to the shell.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 1xxx Codes (services)

These errors are related to the services.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

<dl><dt><strong><a name="note-1040"></a>📌 NOTE: Error 1040</strong></dt><dd>

The Query Service REST API returns this error if you specify request parameters as form data and include an unescaped semicolon (;) in a statement.
</dd></dl>

## 2xxx Codes (admin)

These errors are related to the admin.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 3xxx Codes (parse)

These errors are related to the parsing.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 4xxx Codes (plan)

These errors are related to the query plan.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 5xxx Codes (exec)

These errors are related to the execution.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

<dl><dt><strong><a name="note-5500"></a>📌 NOTE: Error 5500</strong></dt><dd>

You can set a memory quota with the Couchbase Server UI, the REST API, or the CLI.
For more information, see [n1ql:n1ql-manage/query-settings.adoc](n1ql:n1ql-manage/query-settings.adoc).

* To set a memory quota with the UI, see [Query Settings](manage:manage-settings/general-settings.adoc#query-settings) in the General settings for Couchbase Server.
* To set a memory quota with the REST API, see the cluster-level [queryMemoryQuota](n1ql:n1ql-manage/query-settings.adoc#queryMemoryQuota) setting.
* To set a memory quota with the CLI, see [setting-query](cli:cbcli/couchbase-cli-setting-query.adoc) in the CLI Reference.
</dd></dl>

## 9999 Code (error)

This is a general error.

| ICode | Error Message | Description |
| --- | --- | --- |
| `9999` | Not implemented. | **Reason** * The feature is not implemented in this edition.   For example, you attempted to use an Enterprise Edition-only feature in Couchbase Server Community Edition. |

## 10xxx Codes (ds_auth)

These errors are related to the Datastore authentication.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 11xxx Codes (ds_sys)

These errors are related to the Datastore system.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 12xxx Codes (ds_cb)

These errors are related to the Couchbase Datastore.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 13xxx Codes (ds_view)

These errors are related to the Datastore view.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 14xxx Codes (ds_gsi)

These errors are related to the Datastore Global Secondary Index.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 15xxx Codes (ds_file)

These errors are related to the Datastore files.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 16xxx Codes (ds_other)

These errors are related to other Datastore aspects.

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 17xxx Codes

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 18xxx Codes

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 19xxx Codes

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## 20xxx Codes

| ICode | Error Message | Description {{#each data}} {{#if (range code @root.from @root.to)}} |
| --- | --- | --- |
| `{{code}}` | pass:[{The following table lists all of the {sqlpp} error codes, their error message, and some tips to resolve them.}] | {{#with reason}} **Reason** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#with user_action}} **User Action** {{#each .}} * pass:[{{.}}] {{/each}} {{/with}} {{#if footnote}} See [Note](#note-{{code}}). {{/if}} {{/if}} {{/each}} |

## See Also

* The [FINDERR()](n1ql-language-reference/metafun.adoc#finderr) function
* The [finderr](cli:finderr.adoc) command line tool
