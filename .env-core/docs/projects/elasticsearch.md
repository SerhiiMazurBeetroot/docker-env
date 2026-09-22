# Elastic Stack

Elasticsearch with Kibana and Logstash hosts. Disk path: `elasticsearch/{DOMAIN_FULL}/`.

## Create

CLI: **2 New project → Elastic Stack**.

1. Short name
2. Host (default `dev.{name}.local`)
3. Elastic version
4. Confirm with `y`

Nginx must be running. The first start skips an extra container bounce so Elasticsearch health is not raced.

## URLs

| What | Example |
| --- | --- |
| Elasticsearch | `https://dev.search.local` |
| Kibana | `https://dev.search.local.kibana` |
| Logstash | `https://dev.search.local.logstash` |

Hosts extras are added on macOS/Linux. Direct ports on the container (if you inspect Compose): Elasticsearch **9200**, Kibana **5601**.

App container: `{shortname}-elasticsearch`.

[Getting started](../getting-started.md)
