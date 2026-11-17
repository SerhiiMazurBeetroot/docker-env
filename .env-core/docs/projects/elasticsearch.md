# Elastic Stack

Elasticsearch with Kibana and Logstash hosts. Disk path: `elasticsearch/{DOMAIN_FULL}/`.

## Create

CLI: **2 New site → Elastic Stack**.

1. Short name
2. Host (default `dev.{name}.elastic`)
3. Elastic version
4. Confirm with `y`

Nginx must be running. The first start can take a minute while Elasticsearch becomes healthy.

## URLs

| What | Example |
| --- | --- |
| Elasticsearch | `https://dev.search.elastic` |
| Kibana | `https://dev.search.elastic.kibana` |
| Logstash | `https://dev.search.elastic.logstash` |

Hosts extras are added on macOS/Linux. Direct ports on the container (if you inspect Compose): Elasticsearch **9200**, Kibana **5601**.

App container: `{shortname}-elasticsearch`.

[Getting started](../getting-started.md)
