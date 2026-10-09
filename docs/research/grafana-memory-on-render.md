# Keeping Grafana inside 512 MiB on Render

Researched 2026-10-09 for issue #269. The versions checked were Grafana 13.2.3 (`grafana/grafana:13.2.3`, source at the [`v13.2.3` tag](https://github.com/grafana/grafana/tree/v13.2.3)), Prometheus 3.15.0, and PromEx 1.12.0. Render plan facts come from Render's docs as of the same date. Measurements ran locally in Docker on arm64, with each container capped at `--memory=512m --cpus=0.5` to match Render's Starter plan.

## Answer

1. **Set `GF_PLUGINS_PREINSTALL_DISABLED=true` first. It stops Grafana from filling the container with 450 MB of plugin downloads on every boot.** Grafana 13.2.3 has a hard-coded list of 18 "preinstall" plugins, and by default it downloads and auto-updates them at startup. With no disk, it repeats this on every boot. The downloads landed as 452 MB in `/var/lib/grafana/plugins`, and the page cache they created held the container at its 512 MiB limit (`memory.current` 511.5 MiB). Under load, the kernel hit the limit 3,562 times. With the setting on, the container sat at 291 MiB with 0 install lines and 0 limit hits. The env name is correct. In a local test it removed all install lines, so the earlier test that still showed installs most likely did not pass the variable into the container (unverified).
2. **Also set `GF_PLUGINS_DISABLE_PLUGINS` to the 17 plugins Flick never uses. It saves about 110 MiB of real (anonymous) memory.** Each bundled data source runs as its own Go process, at 22 to 38 MB RSS each, even with no data source configured. Disabling everything except `prometheus` left one plugin process and cut anonymous memory from 269 MiB to 169 MiB. Grafana stayed healthy and served all six dashboards. Do this in the same change as item 1, since both are one env var each.
3. **Set `GF_DASHBOARDS_MIN_REFRESH_INTERVAL=30s`, so the PromEx dashboards stop refreshing every 5 seconds.** Grafana rewrites a provisioned dashboard's refresh to the minimum when it is lower, and logs a warning. A local test confirmed that all five PromEx dashboards loaded at `30s`. This cuts query load six-fold and lowered peak memory under load from 293 MiB to 258 MiB. Do not edit `refresh` in the dashboard JSON, because the next `mix prom_ex.dashboard.export` overwrites it.
4. **Do not set `GOMEMLIMIT` for now.** Grafana does not set it on its own, unlike Prometheus. A 150 MiB limit lowered peak memory from 293 MiB to 238 MiB, but it trades memory for garbage-collection CPU on a 0.5 CPU instance. After items 1 to 3, Grafana peaks near 260 to 300 MiB, which leaves over 200 MiB of headroom. Revisit it if production peaks climb past about 400 MiB.
5. **Leave alerting, Live, the news feed, usage reporting, and public dashboards at their defaults.** Turning all five off saved about 10 to 20 MiB, which is within run-to-run noise. It also removes Grafana alerting, which Flick may want later.
6. **Take no action on Prometheus.** Render reports `flick-prometheus` at 28 to 34 MiB of its 512 MiB. Prometheus 3.15 sets `GOMEMLIMIT` from the container limit by default. Flick's PromEx plugins produce about 530 series locally, so `drop_metrics_groups` and relabeling would save almost nothing.
7. **Keep self-hosting, but treat Grafana Cloud's free tier as the fallback if items 1 to 3 do not hold.** Grafana Cloud can scrape Flick's public, basic-auth `/metrics` over HTTPS directly. That would remove both Render services, at $7 a month each per [Render's own comparison](https://render.com/articles/render-vs-railway) (the compute plans page omits prices), plus Prometheus's disk. The cost is 14-day retention instead of the current 800 MB, metrics data leaving Render, and a free-tier data-points-per-minute allowance that Grafana's pages do not state.
8. **Reject the other alternatives.** Render's metrics streaming needs a Pro workspace and sends only platform metrics, not PromEx metrics. Render's free instance has the same 512 MB, 0.1 CPU, and spins down after 15 idle minutes. Running Grafana locally against production Prometheus would mean exposing Prometheus publicly. A persistent disk for Grafana would only cache the downloads that item 1 removes.

Anything not called out above stands as recommended.

Items 1 to 3 went into `instrumentation/grafana/Dockerfile` as `ENV` lines, so the local stack and Render run the same settings from one place:

```dockerfile
ENV GF_PLUGINS_PREINSTALL_DISABLED=true
ENV GF_PLUGINS_DISABLE_PLUGINS=elasticsearch,grafana-postgresql-datasource,grafana-pyroscope-datasource,influxdb,jaeger,loki,mssql,mysql,opentsdb,stackdriver,tempo,zipkin,grafana-advisor-app,grafana-exploretraces-app,grafana-lokiexplore-app,grafana-metricsdrilldown-app,grafana-pyroscope-app
ENV GF_DASHBOARDS_MIN_REFRESH_INTERVAL=30s
```

## Why Grafana downloads plugins at every boot

The installs come from the preinstall feature, not from a separate auto-update mechanism. [`pkg/setting/setting_plugins.go`](https://github.com/grafana/grafana/blob/v13.2.3/pkg/setting/setting_plugins.go) defines `defaultPreinstallPlugins`, a list of 18 plugins: the Loki, Pyroscope, traces, and metrics drilldown apps, the advisor app, and 13 data sources including `prometheus`, `loki`, `influxdb`, and `opentsdb`. Unless `preinstall_disabled` is true, Grafana adds this list to the async install queue. Inside the same branch, `preinstall_auto_update` defaults to true, so Grafana also upgrades plugins that ship bundled in the image. That explains the "Updating plugin ... from=13.0.6 to=13.0.7" lines. The installer in [`plugininstaller/service.go`](https://github.com/grafana/grafana/blob/v13.2.3/pkg/services/pluginsintegration/plugininstaller/service.go) logs `Installing plugin` for each one.

Setting `preinstall_disabled` skips the whole branch, so it turns off both the installs and the auto-update. The [configuration docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/) describe it as "This option disables all preinstalled plugins." Grafana maps `GF_<SECTION>_<KEY>` to ini settings, so the env name is `GF_PLUGINS_PREINSTALL_DISABLED`. Grafana then uses the copies bundled in the image under `/usr/share/grafana/data/plugins-bundled`, which pins the Prometheus plugin to the image tag.

`disable_plugins` is a separate setting. The docs describe it as "a comma-separated list of plugin identifiers to avoid loading (including core plugins)." The same source file also removes disabled plugins from the preinstall list.

## Measurements

Every container ran the repo's `instrumentation/grafana` image with `--memory=512m --cpus=0.5` and `PROMETHEUS_HOST` set. Memory figures come from the container's cgroup: `memory.current` is what the kernel charges against the limit, and `anon` is process memory that cannot be reclaimed. Idle readings are 2 to 3 minutes after boot.

| Variant (env added to the base image) | `memory.current` | `anon` | Plugin processes | Install log lines |
| --- | --- | --- | --- | --- |
| None (today's production config) | 511.5 MiB (at limit) | 257 MiB | 13 | 22 |
| `GF_PLUGINS_PREINSTALL_DISABLED=true` | 291 MiB | 269 MiB | 13 | 0 |
| plus `GF_PLUGINS_DISABLE_PLUGINS` (17 ids) | 179 MiB | 169 MiB | 1 | 0 |
| plus alerting, Live, news, analytics, and public dashboards off | 168 MiB | 161 MiB | 1 | 0 |

In the default variant, 241 MB of the charge was file cache from the downloaded plugins. That cache is reclaimable, but reclaiming it at the limit costs time on every allocation. This is a plausible cause of the slow `/api/health` responses that made Render restart the service, but it is unverified. Render's docs do not say whether its memory graph counts page cache. Render's production graph for `flick-grafana` swung between 274 MiB and 510 MiB from 15:49 to 16:06 UTC on 2026-10-09, which matches a container held near its limit.

To simulate the Phoenix dashboard open, a script sent each panel query of the Phoenix and BEAM dashboards (56 queries) to `/api/ds/query` at once, every 5 seconds for 150 seconds. All 1,568 requests returned 200. The queries ran against the local Prometheus, which held about 530 series, so production responses may be larger.

| Variant under load | Peak `memory.current` |
| --- | --- |
| Default config | 512 MiB (pinned at limit, 3,562 limit hits) |
| Items 1 and 2, 5 s refresh | 293 MiB |
| Items 1 and 2, 30 s refresh | 258 MiB |
| Items 1 and 2, `GOMEMLIMIT=150MiB` | 238 MiB |
| Items 1 and 2, extra features off | 272 MiB |

For the `GOMEMLIMIT` run, `GF_PLUGINS_FORWARD_HOST_ENV_VARS=prometheus` passed the limit to the Prometheus plugin process as well. Without it, only the main Grafana process sees the variable.

## Grafana settings checked

The defaults below come from [`conf/defaults.ini` at v13.2.3](https://github.com/grafana/grafana/blob/v13.2.3/conf/defaults.ini).

- `[dashboards] min_refresh_interval` defaults to `5s`. [`SaveProvisionedDashboard`](https://github.com/grafana/grafana/blob/v13.2.3/pkg/services/dashboards/service/dashboard_service.go) sets a provisioned dashboard's refresh to the minimum when it is lower and logs "Changing refresh interval for provisioned dashboard to minimum refresh interval."
- `[dashboards] default_preload` defaults to false, so panels load only as they scroll into view. The top of the Phoenix dashboard still loads its 24-hour stat panels on open.
- `[live] max_connections` defaults to 100, and 0 disables Live. Flick's dashboards do not use streaming, so Live costs little.
- `[unified_alerting] enabled`, `[news] news_feed_enabled`, `[analytics] reporting_enabled`, `check_for_updates`, `check_for_plugin_updates`, and `[public_dashboards] enabled` all default to on. Turning them off measured within noise.
- `[datasources] concurrent_query_count` applies only to Loki and InfluxDB, so it does not limit Prometheus queries.
- Grafana does not set `GOMEMLIMIT`. Its [`go.mod`](https://github.com/grafana/grafana/blob/v13.2.3/go.mod) has no `automemlimit` dependency, and the image's `/run.sh` sets no Go variables.
- Image rendering is not installed, so there is no server-side rendering memory to reduce.

## Prometheus

Prometheus 3.15.0 imports `automemlimit` and exposes `--auto-gomemlimit` with a ratio flag in [`cmd/prometheus/main.go`](https://github.com/prometheus/prometheus/blob/v3.15.0/cmd/prometheus/main.go). The local container reported `GOMEMLIMIT` at 90% of the memory it could see, and `GOGC` at 75. Render's metrics put `flick-prometheus` at 28 to 34 MiB from 15:50 to 16:05 UTC on 2026-10-09.

The local Prometheus held 528 head series for Flick. The largest groups are Ecto query histograms (56 series each) and LiveView mount histograms (48). PromEx's `drop_metrics_groups` option and Prometheus's `metric_relabel_configs` could trim these, but Prometheus has more than 450 MiB of headroom, so neither is worth doing now.

## Alternatives to self-hosted Grafana

Grafana Cloud's [pricing page](https://grafana.com/pricing/) (read 2026-10-09) lists the free tier at 10k active metrics series, 14-day retention, and 3 active Grafana users. Pro starts at $19 a month plus usage. The [metrics invoice docs](https://grafana.com/docs/grafana-cloud/cost-management-and-billing/manage-invoices/understand-your-invoice/metrics-invoice/) say Pro includes 1 data point per minute per series, and a 15-second scrape sends 4. The free tier's allowance is unverified. A 60-second scrape keeps Flick at 1 DPM in either case.

The [Metrics Endpoint integration](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-metrics-endpoint/) scrapes a public HTTPS URL that requires basic or bearer auth, with a 1-minute default interval. `https://rankedvote.app/metrics` already fits: it returns 401 without credentials. Whether the integration is available on the free tier is unverified.

Render's [compute plans](https://render.com/docs/compute-plans) offer no web or private service size between 512 MB and 2 GB. Render's [free instance](https://render.com/docs/free) has 0.1 CPU, spins down after 15 minutes without traffic, and is not available for private services. [Metrics streams](https://render.com/docs/metrics-streams) need a Pro workspace and carry Render's platform metrics such as CPU and memory, not application metrics. A [persistent disk](https://render.com/docs/disks) can attach to a paid web service, but with preinstall disabled Grafana has nothing worth keeping on it.
