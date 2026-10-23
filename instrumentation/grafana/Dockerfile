FROM grafana/grafana:13.2.3

# Grafana sends alerts to ntfy.sh over TLS. This image's CA bundle still
# trusts the compromised eMudhra intermediates, so a forged certificate could
# intercept those alerts. Alpine's 20261020 packages remove those
# intermediates. Drop this step once a Grafana tag ships those packages.
# See https://github.com/zorn/flick/issues/317
USER root
RUN apk upgrade --no-cache ca-certificates ca-certificates-bundle
# 472 is the base image's grafana user.
USER 472

# Render's Starter plan gives Grafana 512 MiB. These settings keep it well
# under that. See docs/research/grafana-memory-on-render.md.
#
# With no disk, Grafana downloads 18 plugins at every boot. Flick needs only
# the bundled Prometheus data source. Plugin fixes, security fixes included,
# now arrive only when the image tag changes.
ENV GF_PLUGINS_PREINSTALL_DISABLED=true
# Each bundled plugin runs as its own process, even when unused. On every tag
# bump, recheck this list against /usr/share/grafana/data/plugins-bundled.
ENV GF_PLUGINS_DISABLE_PLUGINS=elasticsearch,grafana-postgresql-datasource,grafana-pyroscope-datasource,influxdb,jaeger,loki,mssql,mysql,opentsdb,stackdriver,zipkin,grafana-advisor-app,grafana-exploretraces-app,grafana-lokiexplore-app,grafana-metricsdrilldown-app,grafana-pyroscope-app
# The PromEx dashboards refresh every 5 seconds, but Prometheus scrapes every
# 15. Grafana raises those dashboards to this minimum, and the refresh picker
# offers nothing faster.
ENV GF_DASHBOARDS_MIN_REFRESH_INTERVAL=30s

COPY provisioning /etc/grafana/provisioning
COPY dashboards /etc/grafana/dashboards
