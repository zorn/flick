#!/bin/sh
# Starts Prometheus with local.yml, or with the file named in PROMETHEUS_CONFIG.
set -eu

# Prometheus can't read environment variables in a scrape config, so
# render.yml reads the credentials and target from files. The umask makes each
# file readable by its owner only, and the subshell keeps that umask away from
# Prometheus.
write_private() {
  (umask 077; printf '%s' "$2" > "$1")
  chown nobody:nobody "$1"
}

if [ "${PROMETHEUS_CONFIG:-local.yml}" = render.yml ]; then
  # A missing variable would leave Prometheus running with no targets and only
  # a log line to show for it. Fail the deploy instead.
  : "${FLICK_HOST:?must be set for render.yml}"
  : "${METRICS_AUTH_USERNAME:?must be set for render.yml}"
  : "${METRICS_AUTH_PASSWORD:?must be set for render.yml}"

  write_private /tmp/metrics_auth_username "$METRICS_AUTH_USERNAME"
  write_private /tmp/metrics_auth_password "$METRICS_AUTH_PASSWORD"

  # Render's private network reaches a web service's HTTP server on port 10000.
  printf '[{"targets": ["%s:10000"]}]\n' "$FLICK_HOST" > /tmp/flick_targets.json
fi

chown -R nobody:nobody /prometheus

exec chpst -u nobody:nobody /bin/prometheus \
  --config.file="/etc/prometheus/${PROMETHEUS_CONFIG:-local.yml}" \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.size=800MB
