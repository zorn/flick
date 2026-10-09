#!/bin/sh
# Starts Prometheus with local.yml, or with the file named in PROMETHEUS_CONFIG.
set -eu

# Prometheus can't read environment variables in a scrape config, so the
# password reaches it through a file. The umask makes the file readable by
# its owner only, and the subshell keeps that umask away from Prometheus.
if [ -n "${METRICS_AUTH_PASSWORD:-}" ]; then
  (umask 077; printf '%s' "$METRICS_AUTH_PASSWORD" > /tmp/metrics_auth_password)
  chown nobody:nobody /tmp/metrics_auth_password
fi

# The script starts as root so it can take over the disk, whoever owns it.
# Prometheus itself runs as nobody, like in the official image.
chown -R nobody:nobody /prometheus

exec chpst -u nobody:nobody /bin/prometheus \
  --config.file="/etc/prometheus/${PROMETHEUS_CONFIG:-local.yml}" \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.size=800MB
