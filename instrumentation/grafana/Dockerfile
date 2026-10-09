FROM grafana/grafana:13.2.3

# Render's Starter plan gives Grafana 512 MiB. These settings keep it well
# under that. See docs/research/grafana-memory-on-render.md.
#
# With no disk, Grafana downloads 18 plugins at every boot. Flick needs only
# the bundled Prometheus data source.
ENV GF_PLUGINS_PREINSTALL_DISABLED=true
# Each bundled plugin runs as its own process, even when unused.
ENV GF_PLUGINS_DISABLE_PLUGINS=elasticsearch,grafana-postgresql-datasource,grafana-pyroscope-datasource,influxdb,jaeger,loki,mssql,mysql,opentsdb,stackdriver,tempo,zipkin,grafana-advisor-app,grafana-exploretraces-app,grafana-lokiexplore-app,grafana-metricsdrilldown-app,grafana-pyroscope-app
# The PromEx dashboards refresh every 5 seconds, but Prometheus scrapes every
# 15. Grafana raises any faster refresh to this minimum.
ENV GF_DASHBOARDS_MIN_REFRESH_INTERVAL=30s

COPY provisioning /etc/grafana/provisioning
COPY dashboards /etc/grafana/dashboards
