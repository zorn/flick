FROM prom/prometheus:v3.15.0

# Render's docs don't say who owns a mounted disk, so the entrypoint starts as
# root to take it over, then runs Prometheus as nobody.
USER root

COPY local.yml render.yml /etc/prometheus/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
