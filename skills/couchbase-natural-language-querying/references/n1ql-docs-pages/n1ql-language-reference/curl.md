# CURL Function

<style type="text/css">
  /* No maximum width for table cells */
  .doc table.spread > tbody > tr > *,
  .doc table.stretch > tbody > tr > * {
    max-width: none !important;
  }

  /* Ignore fixed column widths */
  col{
    width: auto !important;
  }

  /* Wrap inline code in tables */
  td.tableblock p code,
  p.tableblock code{
    overflow-wrap: anywhere;
  }

  /* Do not hyphenate words in the table */
  td.tableblock p,
  p.tableblock{
    hyphens: manual;
  }

  /* Vertical alignment */
  td.tableblock{
    vertical-align: top !important;
  }

  /* Spacing for markdown blocks */
  .doc .openblock > .content > p {
    margin-top: 1rem;
  }

  .doc .openblock > .content > ul,
  .doc .openblock > .content > ol {
    margin-top: 1.5rem;
    margin-left: 1rem;
  }

  .doc .openblock > .content > ul li + li,
  .doc .openblock > .content > ol li + li {
    margin-top: 0.5rem;
  }
</style>

The `CURL()` function implements a subset of [cURL](https://en.wikipedia.org/wiki/CURL) functionality and enables {sqlpp} queries to interact and integrate with external JSON data sources available over HTTP/REST.
This allows federated queries against external data sources, such as the [Google geocoding API](https://maps.googleapis.com), [Yahoo API](https://developer.yahoo.com/api/), or other Couchbase clusters.
The federated queries can use full querying capabilities of {sqlpp}, including functions, expressions, subqueries, JOINs, NESTs, UNNESTs, and so on.

You can use the `CURL()` function in various {sqlpp} expressions and clauses of DML statements such as projection, WHERE predicates, FROM data source, and more.
For example, you can use it with an INSERT-SELECT statement to import external data into Couchbase Server.

## Syntax

```ebnf
curl-function ::= 'CURL' '(' url (',' options)? ')'
```

### Arguments

* **url**\
A string representing the URL of the data source.
The URL needs to point to a JSON endpoint and must be either `http://` or `https://` only.
No other protocol is supported.
The redirection of URLs is not allowed.
* **options**\
An optional JSON object representing various supported options.
This includes options and parameters to be sent to the URL source endpoint.

### Options

**Security Options**

| Option | Description | Value |
| --- | --- | --- |
| **user** | Server user name and password, in the form `USERNAME[:PASSWORD]` | String |
| **basic** | Use HTTP Basic Authentication. | Boolean |
| **insecure** | Allow connections to SSL sites without certificates (H). | Boolean |
| **anyauth** | CURL to figure out authentication method by itself, and use the most secure one. NOTE: This supports only basic authentication. | Boolean |
| **cacert** | The CA signed certificate filename. Certificates should be stored on the local machine, on each query node within a cluster. * To store certificates, access `/Couchbase/var/lib/couchbase/n1qlcerts`. This is not visible to the user. * The filename cannot contain a path. * If the certificate is not a match to the existing contents of `n1qlcerts` directory, the function returns an error. * All expired and invalid certificates return an error. * When you add a new node, the `cacert` file must be copied to the new node and must have read access. * If this option is omitted, the `insecure` option must be true. For example, this is the certificate `.pem` file for AWS. | String |
| **cert** | The chain certificate filename. Certificates should be stored on the local machine, on each query node within a cluster. * To store certificates, access `/Couchbase/var/lib/couchbase/n1qlcerts`. This is not visible to the user. * The filename cannot contain a path. * If the certificate is not a match to the existing contents of `n1qlcerts` directory, the function returns an error. * All expired and invalid certificates return an error. * When you add a new node, the `cert` file must be copied to the new node and must have read access. * If this option is omitted, the `insecure` option must be true. Example: `"chain.pem"` | String |
| **key** | The client key filename. Key files should be stored on the local machine, on each query node within a cluster. If the key file is encrypted, it should use PKS8 v2, and you must supply the passphrase to decrypt it. * To store key files, access `/Couchbase/var/lib/couchbase/n1qlcerts`. This is not visible to the user. * The filename cannot contain a path. * If the key file is not a match to the existing contents of `n1qlcerts` directory, the function returns an error. * All expired and invalid certificates return an error. * When you add a new node, the `key` file must be copied to the new node and must have read access. * If this option is omitted, the `insecure` option must be true. Example: `"client.key"` | String |
| **passphrase** | The passphrase to decrypt the key file. Owing to its sensitive nature, you’re recommended to use a named parameter for this option. The parameter name should start and end with an underscore `_` to mask the parameter value in request catalogs, cbq shell history, query logs, and so on. Example: `$_passphrase_` | String |

**Transfer-related Options**

| Option | Description | Value |
| --- | --- | --- |
| **get** | If true, perform a GET request. Example: `true` | Boolean |
| **request** | Sets the request method. This only accepts GET or POST requests. This is case sensitive. Example: `"POST"` | String |
| **connect-timeout** | The maximum time allowed for connection in seconds. Example: `30` | Integer |
| **max-time** | The maximum time allowed for the transfer in seconds. Example: `30` | Integer |
| **data** | POST data to be sent to the HTTP/REST service. The string data should be formatted exactly same as HTTP POST data. Examples: `"address=Half+Moon+Bay"` `"address=Half+Moon+Bay,california"` | String or array of strings |
| **header** | Passes custom header line to the server. To send the user-agent string to the server, add the value to this parameter. Examples: `"Content-Type: application/json"` `["Content-Type: application/json", "Content-Length: 115"]` `["user-agent: bsmith","Content-Type: application/json"]` | String or array of strings |
| **show-error** | If true, display error message. Example: `true` | Boolean |
| **silent** | If true, use silent mode. Example: `false` | Boolean |
| **keepalive-time** | The number of seconds to wait between the `keepalive` probes. Example: `20` | Integer |
| **data-urlencode** | Like the `data` option, but URL-encodes the data. For example, `this is a test` is encoded as `this%20is%20a%20test` | String or array of strings |

### Return Value

The `CURL()` function returns the response from the HTTP/REST service at the specified URL as one of the following:

* A single JSON object
* An array of JSON objects

The function returns the data as is, without any additional processing.

If you include the query parameter `pretty=true`, the function returns the data in a formatted, readable JSON structure.

Responses that are not in a well-defined JSON format can result in errors or undefined behavior.
For example, if the URL returns any other format other than JSON, the function returns `Not a JSON endpoint` error.

The function can return errors in different formats such as HTML, XML, plain strings, or a large blob.

## Security

The `CURL()` function can connect to any REST end point accessible to the Query node, inside or outside the firewall.
To avoid security vulnerabilities, the `CURL()` function includes multiple security measures and options.
You can use them to control and minimize the risks associated with using the function.
For a complete list of security options, see [table_security_options](#table_security_options).

Additionally, a Full Administrator can define a list of URLs and REST endpoints that the `CURL()` function can access.
The `CURL()` function can access only URLs that match a specified prefix, meaning only URLs specified on the list or their prefixes are accessible.

Consider a use case where a deployment of Couchbase Server and Mobile Sync Gateway exist on the same machine, and the user has access to the Query Service but not the Sync Gateway Admin endpoint.
If the Full Administrator grants the user the `QUERY_EXTERNAL_ACCESS` role, the user can write queries using the `CURL()` function and potentially access the Sync Gateway Admin endpoint.
To avoid this, the Full Administrator can create an access list for `CURL()` and add the Sync Gateway Admin endpoint to the `disallowed_urls` list.

For more information on creating the access list and the structure of the access list file, see [Creating an Access List for CURL()](#creating-an-access-list-for-curl).

The following security measures help control risks when using the `CURL()` function:

* Enable the `CURL()` function only for the Full Administrator role.
* For all other users, the RBAC role `QUERY_EXTERNAL_ACCESS` is required to run the `CURL()` function.
Only the Full Administrator can assign the `QUERY_EXTERNAL_ACCESS` role to other users.
* An access list of URLs and REST points must be configured on the query nodes before being able to use the `CURL()` function.
See [Creating an Access List for CURL()](#creating-an-access-list-for-curl) for details.
* Each query node in the cluster must define its access list file.
* The `CURL()` function internally supports a specific set of SSL ciphers (MEDIUM or HIGH).
This is dependent on the `COUCHBASE_SSL_CIPHER_LIST`.
* The `CURL()` function runs on the query node within a cluster.
In order to identify a request from {sqlpp}'s `CURL()` function, a custom header is always set for all requests.
The custom header format is: `"X-N1QL-User-Agent: couchbase/n1ql/<n1ql-version>"`.
External clients that wish to disallow {sqlpp} `CURL()` from accessing their REST API endpoints can explicitly check for the above header and block it.
The general external endpoints will ignore this header value.
* A `user-agent` is always set by default.
This can be reset using the `-user-agent` option.
The value set by default is `couchbase/n1ql/<n1ql-version>`.

  **📌 NOTE**\
  The current <n1ql-version> is "1.7.0-N1QL".

### Creating an Access List for CURL()

An access list allows a Full Administrator to list out the permitted REST endpoints and URLs for the `CURL()` function.
To enable access based on the access list, a Full Administrator must create the file containing the access list, which can be created two ways:

1. From the Query Workbench UI in the menu:Settings[Advanced Query Settings] section.
2. From CBQ via a cURL command.

#### From the Query Workbench

To create an access list for the `CURL()` function from the Query Workbench:

1. Go to the menu:Settings[Query] tab.
2. Under **CURL() Function Access**, select one of the following options:

   * **Restricted**:: Access applies only the sites explicitly listed.
   * **Unrestricted**:: Access applies to all sites within the explicitly listed sites.
3. Under the **Allowed CURL URLs** and **Disallowed CURL URLs** headings, enter your allowed or disallowed URL in the appropriate text field.
4. Press kbd:[Enter] or click anywhere outside the text field to save the URL.
5. To add another URL, click btn:[+].
6. To remove a URL, click btn:[-].

#### From the Query Settings REST API

You can send a call to the Query Settings REST API to allow or disallow specific URLs, for example:

```sh
curl -v -X POST -u Administrator:password \
http://localhost:8091/settings/querySettings/curlWhitelist \
-d '{"all_access": false,
     "allowed_urls": ["https://company1.com"],
     "disallowed_urls": ["https://company2.com"]}'
```

The access list file command structure is described in the following table.

**Structure of Access List for CURL()**

[role=include](n1ql-rest-settings:index.adoc)

## Design Considerations

When using CURL, consider the following:

* The URL must point to a JSON endpoint.
The redirection of URL is not allowed.
* Only HTTP and HTTPS protocols are supported.
You cannot access files on the local filesystem.
* The amount of memory used for the CURL result is controlled using the `result-cap` option.
The default is 20MB.

## Examples

1. [xrefstyle=basic](#Ex1)
2. [xrefstyle=basic](#Ex2)
3. [xrefstyle=basic](#Ex3)
4. [xrefstyle=basic](#Ex4)
5. [xrefstyle=basic](#Ex5)
6. [xrefstyle=basic](#Ex6)
7. [xrefstyle=basic](#Ex7)
8. [xrefstyle=basic](#Ex8)
9. [xrefstyle=basic](#Ex9)
10. [xrefstyle=basic](#Ex10)
11. [xrefstyle=basic](#Ex11)
12. [xrefstyle=basic](#Ex12)
13. [xrefstyle=basic](#Ex13)
14. [xrefstyle=basic](#Ex14)

The following examples are using CURL in the query projection list.

<a name="Ex1"></a>**Use Google Maps API to convert static address into coordinates**

The following {sqlpp} query and `curl` command fetch details about the address `"Half Moon Bay"` using the [Google maps API](https://maps.googleapis.com).
The Geocoding API from Google Maps allows you to convert static addresses into coordinates.
For more information, see the [Geocoding API Developer Guide](https://developers.google.com/maps/documentation/geocoding/intro).

**Request**

```sh
curl https://maps.googleapis.com/maps/api/geocode/json?address=Half+Moon+Bay
```

**Query**

```sqlpp
SELECT CURL("https://maps.googleapis.com/maps/api/geocode/json",
           {"data":"address=Half+Moon+Bay" , "request":"GET"} );
```

**Results**

```json
[
  {
    "$1": {
      "results": [
        {
          "address_components": [
            {
              "long_name": "Half Moon Bay",
              "short_name": "Half Moon Bay",
              "types": [
                "locality",
                "political"
              ]
            },
            {
              "long_name": "San Mateo County",
              "short_name": "San Mateo County",
              "types": [
                "administrative_area_level_2",
                "political"
              ]
            },
            {
              "long_name": "California",
              "short_name": "CA",
              "types": [
                "administrative_area_level_1",
                "political"
              ]
            },
            {
              "long_name": "United States",
              "short_name": "US",
              "types": [
                "country",
                "political"
              ]
            }
          ],
          "formatted_address": "Half Moon Bay, CA, USA",
          "geometry": {
            "bounds": {
              "northeast": {
                "lat": 37.5226389,
                "lng": -122.4165183
              },
              "southwest": {
                "lat": 37.4249286,
                "lng": -122.4778879
              }
            },
            "location": {
              "lat": 37.4635519,
              "lng": -122.4285862
            },
            "location_type": "APPROXIMATE",
            "viewport": {
              "northeast": {
                "lat": 37.5226389,
                "lng": -122.4165183
              },
              "southwest": {
                "lat": 37.4249286,
                "lng": -122.4774494
              }
            }
          },
          "place_id": "ChIJC8sZCqULj4ARVJvnNcic_V4",
          "types": [
            "locality",
            "political"
          ]
        }
      ],
      "status": "OK"
    }
  }
]
```

<a name="Ex2"></a>**Use Google Maps API to extract geometry (address and geographic location bounds) of a given street address**

This is similar to [Use Google Maps API to convert static address into coordinates](#Ex1), but following {sqlpp} query fetches details about Santa Cruz in Spain using the [Google geocoding API](https://maps.googleapis.com) and extracts the `geometry` field from the result.
This query retrieves the address and geographic location bounds of the address, Santa Cruz, ES, by using the `address` and `components` parameters from the Geocoding API.
The `data` option specifies the HTTP POST data.

**Request**

```sh
curl https://maps.googleapis.com/maps/api/geocode/json?address=santa+cruz&components=country:ES
```

**Query**

```sqlpp
SELECT CURL("https://maps.googleapis.com/maps/api/geocode/json",
           {"data":["address=santa+cruz","components=country:ES"],"get":true});
```

**Results**

```json
[
  {
    "$1": {
      "results": [
        {
          "address_components": [
            {
              "long_name": "Santa Cruz de Tenerife",
              "short_name": "Santa Cruz de Tenerife",
              "types": [
                "locality",
                "political"
              ]
            },
            {
              "long_name": "Santa Cruz de Tenerife",
              "short_name": "TF",
              "types": [
                "administrative_area_level_2",
                "political"
              ]
            },
            {
              "long_name": "Canary Islands",
              "short_name": "CN",
              "types": [
                "administrative_area_level_1",
                "political"
              ]
            },
            {
              "long_name": "Spain",
              "short_name": "ES",
              "types": [
                "country",
                "political"
              ]
            }
          ],
          "formatted_address": "Santa Cruz de Tenerife, Spain",
          "geometry": {
            "bounds": {
              "northeast": {
                "lat": 28.487616,
                "lng": -16.2356646
              },
              "southwest": {
                "lat": 28.4280248,
                "lng": -16.3370045
              }
            },
            "location": {
              "lat": 28.4636296,
              "lng": -16.2518467
            },
            "location_type": "APPROXIMATE",
            "viewport": {
              "northeast": {
                "lat": 28.487616,
                "lng": -16.2356646
              },
              "southwest": {
                "lat": 28.4280248,
                "lng": -16.3370045
              }
            }
          },
          "place_id": "ChIJcUElzOzMQQwRLuV30nMUEUM",
          "types": [
            "locality",
            "political"
          ]
        }
      ],
      "status": "OK"
    }
  }
]
```

<a name="Ex3"></a>**Join two keyspaces on different Couchbase clusters**

This {sqlpp} query shows how to JOIN two keyspaces on different Couchbase clusters.
The JOIN is the same as is explained in [JOIN Clause](n1ql-language-reference/join.adoc), but the left and right side keyspaces are in two different Couchbase clusters.

* The left side keyspace `route` is from the cluster running on `hostname`.
If you do not have a second cluster running, you should substitute the `hostname` with 127.0.0.1 or the IP-address of the local cluster.
* The right side keyspace `airline` is from the local cluster.

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
SELECT DISTINCT airline.name, airline.callsign,
   route.destinationairport, route.stops, route.airline
FROM CURL("http://localhost:8093/query/service",
   {"data": "statement=SELECT * FROM route t
                       WHERE t.sourceairport = 'SFO'
           & query_context=travel-sample.inventory",
    "user": "Administrator:password"}).results[*].t route
JOIN airline
ON KEYS route.airlineid
LIMIT 4;
```

The results from the `CURL()` output are embedded in the `results[]` array under the keyspace alias `t` used in the remote query.
To extract the result documents for the left side keyspace of the `JOIN`, use the expression
`CURL(...).results[*].t` and alias it as `route`.

RBAC credentials are required when `CURL()` accesses Couchbase Server version 5.0 or later.

**Results**

```json
[
  {
    "airline": "B6",
    "callsign": "JETBLUE",
    "destinationairport": "AUS",
    "name": "JetBlue Airways",
    "stops": 0
  }, // …
]
```

<a name="Ex4"></a>**Full text search (FTS) in a {sqlpp} query**

The following example shows how to use the `CURL()` function to include a full-text search from the [Search Service](fts:full-text-intro.adoc) in a {sqlpp} query.
If the FTS index `fts_travel` is created on the default collection in the default scope of the `travel-sample` dataset, running the following query finds all documents that contain `"sanfrancisco"`.

In Couchbase Server 6.5 and later, you can use [Search functions](n1ql-language-reference/searchfun.adoc) to use a full-text search in a query, as long as the Search Service is available on the cluster.
However, to access the Search Service on another cluster, you must use the `CURL()` function.

**Query**

```sqlpp
SELECT result.hits[*].id
FROM CURL("http://Administrator:password@127.0.0.1:8094/api/index/fts_index/query",
     {"header":"Content-Type: application/json",
      "request" : "POST",
      "data":'{"explain":false,"fields": ["*"],"highlight": {},
              "query": {"query": "san fran isco"}}' }) result;
```

**Results**

```json
[
  {
    "id": [
      "hotel_25509",
      "hotel_25508",
      "hotel_26139",
      "hotel_25587",
      "hotel_25503",
      "hotel_25667",
      "hotel_25502",
      "hotel_25597",
      "hotel_26493",
      "hotel_25670"
    ]
  }
]
```

<a name="Ex5"></a>**Use Yahoo Finance API in a WHERE clause to find a stock’s lowest value for the day**

The following example uses the `CURL()` function with a WHERE clause.
It uses the Yahoo finance API to find the day’s low value (i.e `DaysLow`) of HDP stock and finds all the documents in the `users` keyspace that have `min_threshold` attribute value greater than the DaysLow stock value.

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Insert the following documents, representing customers and their minimum thresholds, into the default collection in the default scope of the travel sample data, and then run the `SELECT` query:

**Data**

```sqlpp
INSERT INTO `travel-sample` (KEY, VALUE)
  VALUES
     ("k1",
         {"custID" : 12345, "min_threshold" : 4}),
     ("k2",
         {"custID" : 44444, "min_threshold" : 12});
```

**Query**

```sqlpp
SELECT min_threshold,
       meta().id,
       to_number(hdp_low) hdp_low
FROM `travel-sample`
USE KEYS ["k1", "k2"]
LET hdp_low = curl("https://query.yahooapis.com/v1/public/yql", {"data":"q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22HDP%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="}).query.results.quote.DaysLow
WHERE to_number(hdp_low) < min_threshold;
```

**Results**

```json
[
  {
    "hdp_low": 9.48,
    "id": "k2",
    "min_threshold": 12
  }
]
```

<a name="Ex6"></a>**Allow two URLs and disallow one URL**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": true,
"allowed_urls" : ["company1.com", "couchbase.com"],
"disallowed_urls" : ["company2.com"]
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex7"></a>**Allow all access to all endpoints**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": true
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex8"></a>**Turn off access to all endpoints and clear the Allowed and Disallowed lists**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false,
"allowed_urls" : [],
"disallowed_urls" : []
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex9"></a>**Turn off access to all endpoints but make no changes to the Allowed and Disallowed lists**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex10"></a>**Turn off access to all endpoints, allow one URL, and clear the Disallowed list**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false,
"allowed_urls" : ["https://maps.googleapis.com/maps/api/geocode/json"],
"disallowed_urls" : []
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex11"></a>**Turn off access to all endpoints, disallow one URL, and clear the Allowed list**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false,
"disallowed_urls" : ["https://maps.googleapis.com/maps/api/geocode/json"],
"allowed_urls" : []
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex12"></a>**Allow an IP address and port instead of a website name**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false,
"disallowed_urls" : ["https://maps.googleapis.com/maps/api/geocode/json"],
"allowed_urls" : ["http://127.0.0.1:9499/query/service"]
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex13"></a>**Allow and disallow the same URL -- and get an error**

**Request**

```sh
curl -X POST -u Administrator:password \
-d '{
"all_access": false,
"disallowed_urls" : ["https://maps.googleapis.com/maps/api/geocode/json"],
"allowed_urls" : ["https://maps.googleapis.com/maps/api/geocode/json"]
}' http://localhost:8091/settings/querySettings/curlWhitelist
```

<a name="Ex14"></a>**Use CURL() with dynamic named parameters**

**Query**

```sqlpp
SELECT CURL(b.url, $params) FROM keyspace b WHERE b.username = "joe";
```

To execute the query in Node.js, use:

```javascript
keyspace.query(SELECT CURL(b.url, $params) FROM keyspace b WHERE b.username = "joe", { params: { data: "..." } },
 (error, result) => {} );
```

Because `$params` is a named parameter, you must define it within the parameters object when executing the query.
You can populate these properties dynamically using data from your documents.
