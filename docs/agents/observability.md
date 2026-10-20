# Observability

Flick exposes Prometheus metrics at `/metrics` through PromEx (`FlickWeb.PromEx`), behind basic auth. In development, the credentials are `flick-metrics` / `unsafe-metrics-password`. Flick's own metrics come from `FlickWeb.PromEx.RankedVotingPlugin`.

`instrumentation/` holds a Prometheus and Grafana stack that runs the same images locally and on Render. Use it to check how a change affects latency or query counts before you deploy. Start it from the project root while Flick runs on port 4000:

```sh
docker compose -f instrumentation/compose.yml up -d --build
```

Query Prometheus at `http://localhost:9091` through its HTTP API. Prometheus scrapes every 15 seconds, so wait at least that long after a change, and use a rate window of at least `[1m]`:

```sh
# Is Prometheus scraping Flick? 1 means yes.
curl -s localhost:9091/api/v1/query --data-urlencode 'query=up{job="flick"}' | jq '.data.result'

# Requests per second by route over the last 5 minutes.
curl -s localhost:9091/api/v1/query --data-urlencode 'query=sum by (path) (rate(flick_prom_ex_phoenix_http_requests_total[5m]))' | jq '.data.result'

# p95 time to cast a vote, in milliseconds, by result.
curl -s localhost:9091/api/v1/query --data-urlencode 'query=histogram_quantile(0.95, sum by (le, result) (rate(flick_ranked_voting_create_vote_duration_milliseconds_bucket[5m])))' | jq '.data.result'

# Database queries per second by table.
curl -s localhost:9091/api/v1/query --data-urlencode 'query=sum by (source) (rate(flick_prom_ex_ecto_repo_query_total_time_milliseconds_count[5m]))' | jq '.data.result'
```

To list every metric name, run `curl -s localhost:9091/api/v1/label/__name__/values | jq`. An empty result means no event happened in the window, not that the value is zero. In development, every request also shows `schema_migrations` queries from Phoenix's pending-migration check, so subtract that noise when you count a page's queries.

Grafana runs at `http://localhost:3001` with no login. Its data source and dashboards are provisioned from `instrumentation/grafana/`, and Grafana keeps no state between restarts. A dashboard created or edited only in the UI is lost when the container is recreated. To keep one, save its JSON model and rebuild:

```sh
curl -s localhost:3001/api/dashboards/uid/UID | jq '.dashboard | del(.id)' > instrumentation/grafana/dashboards/NAME.json
```

The uid is the part of the dashboard's URL after `/d/`. Keep `uid` so the dashboard's URL stays the same across rebuilds and machines. Remove `id`, because it belongs to one Grafana database. To add a panel without the UI, edit the JSON file and rebuild. Point panels at the data source uid `prometheus`, and use `[$__rate_interval]` as the rate window instead of a fixed one.

On Render, the same images run as `flick-prometheus` and `flick-tempo`, which are private services with no public URL. Grafana runs as `flick-grafana`, which requires a login. Verify changes against the local stack. Only a person with the Grafana login can view production data. Prometheus also scrapes itself and Tempo (jobs `prometheus` and `tempo`), keeping only their disk and memory series. The "Flick stack" dashboard shows them, and the "Tempo disk filling" rule warns three days before Tempo's trace data would pass 800 MB.

Alert rules live in `instrumentation/grafana/provisioning/alerting/alerting.yml` and are read-only in the Grafana UI. Locally, alerts go to the ntfy container: read them at `http://localhost:8081` on the `flick-alerts` topic. To test a rule, cause its condition locally and wait for the alert. For example, stop Flick to fire "Flick not scraped". In production, alerts go to the ntfy.sh topic URL in `NTFY_URL` on Render. Never write that topic into the repo.

Flick sends OpenTelemetry traces to Tempo, which the same stack runs. Each HTTP request, LiveView callback, and Ecto query becomes a span. A LiveView event is its own trace, because it arrives over the WebSocket. Query Tempo at `http://localhost:3200`. Search leaves out the newest 30 seconds, so wait at least 40 seconds after causing the request you want. Always pass `start` and `end`:

```sh
# The last 20 vote saves in the past hour.
curl -sG localhost:3200/api/search \
  --data-urlencode 'q={ name = "FlickWeb.Vote.VoteCaptureLive.handle_event#save" }' \
  --data-urlencode "start=$(($(date +%s) - 3600))" --data-urlencode "end=$(date +%s)" | jq '.traces'

# One trace, with its spans in a compact form.
curl -s -H 'Accept: application/vnd.grafana.llm' localhost:3200/api/v2/traces/TRACE_ID | jq
```

Spans never hold SQL text, LiveView params, IP addresses, user agents, or ballot secrets. Keep it that way. `FlickWeb.TraceScrubber` wraps the exporter and scrubs every span, exception events included. `FlickWeb.TraceSampler` drops `/metrics`, the LiveView socket transports, and static files. Never set `OTEL_TRACES_EXPORTER` or `OTEL_TRACES_SAMPLER`, because they replace those modules. Flick refuses to boot when one is set.

To inspect a live node, open a remote IEx shell and start observer_cli. It shows memory, scheduler use, and the processes with the most memory or the longest mailboxes. Metrics and traces do not show these. `remote` starts a second VM on the same 512 MB instance, so when memory is already near the limit, prefer a single `:recon` call to leaving observer_cli open. In production, open the Shell tab of the `flick` service in the Render dashboard, then attach to the running release:

```sh
_build/prod/rel/flick/bin/flick remote
```

In that shell, run `:observer_cli.start()`. Press `q` and then Enter to quit observer_cli. Quitting leaves the node running. Never run `System.stop/0` or `:init.stop/0` in the remote shell, because they stop production. Leave the shell with Ctrl+C and then `a`, which closes only the remote shell. The release also includes `:recon` for one-off queries such as `:recon.proc_count(:memory, 10)`.

Phoenix LiveDashboard runs at `/admin/dashboard`, behind the same basic auth as `/admin/ballots`. In development, the credentials are `flick-admin` / `unsafe-password`. In production, they come from `BASIC_AUTH_ADMIN_USERNAME` and `BASIC_AUTH_ADMIN_PASSWORD`. Its Processes page shows each process's dictionary and stack trace, but not its state. It still exposes the node's internals, so never move it out of the `/admin` scope. Its Ecto Stats page reads table sizes, index usage, and locks through `ecto_psql_extras` over the private network. It needs no remote shell and starts no second VM, so try it before observer_cli. Use observer_cli when the web endpoint cannot serve a LiveView.

`rel/env.sh.eex` binds EPMD and Erlang distribution to loopback and names the node `flick@localhost`, so only a shell inside the container can reach it. Keep it that way. Never expose distribution on Render's network, and never set a custom release cookie. The default cookie never leaves the container. A custom cookie would sit in Render's environment variables, and its only use is connecting from outside, where a cookie grants full code execution on the node.
