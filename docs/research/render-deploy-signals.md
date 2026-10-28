# How an agent learns about a Render deploy

Researched 2026-10-13 for issue #287. Render facts come from render.com/docs and api-docs.render.com as read that day. Deploy data comes from the read-only Render MCP tools against the `flick` service (`srv-cr590j08fa8c73acf5u0`) and from the GitHub API for `zorn/flick`. Claude Code routine facts come from the [routines docs](https://code.claude.com/docs/en/routines), which mark the feature as a research preview.

## Answer

1. **Use a GitHub Action that runs on `push` to `main` and polls Render's deploy API for that commit. It is the only signal that works for Flick today with no new infrastructure.** The Action already knows the commit, it can hold secrets, and it can call anything when the deploy ends: its own smoke checks, a routine's `/fire` endpoint, or an issue comment. Polling costs one `GET` every 10 to 20 seconds against a 400-per-minute limit. A deploy took 1 to 3 minutes in the last week.
2. **Do not rely on GitHub `deployment_status` for Flick. Render posts GitHub deployments for `flick-grafana` and `flick-prometheus`, but not for `flick`.** The repo has 8 Render-created deployments since 2026-10-09, all in the environments `main - flick-grafana` and `main - flick-prometheus`. The `flick` deploy of `a11112b` on 2026-10-12 created none. Render's docs do not describe this feature, so the cause is unverified. A likely guess is that `flick` predates the Blueprint (created 2024-08-25), while the other two were born from it.
3. **Treat Render webhooks as the push-based upgrade, not the starting point.** They need a Pro workspace, and the Flick workspace appears to be Pro (see below). But Render cannot add an `Authorization` header, and both a routine's `/fire` endpoint and GitHub's `repository_dispatch` need one. A webhook therefore needs a relay that checks Render's signature and forwards the call. That relay is new code with a secret to guard.
4. **Do not use Render notifications as an agent trigger.** They go only to email and Slack. Success notices reach Slack only.
5. **Use a scheduled routine only as a backstop.** Routines run at most hourly, and Claude Code GitHub triggers cover only pull request and release events, not `push` or `deployment_status`.
6. **After a deploy, the agent can check a public page, `/metrics` with basic auth, and Render's events, logs, and metrics APIs. None of these needs a Grafana login.** The weakest point is that `live` on Render means only that a TCP port opened. Flick has no `healthCheckPath`, so a deploy whose app answers every request with a 500 still reports `live`.
7. **Expose the running commit in `/metrics`, so the agent can confirm which code is serving.** PromEx's `application_git_sha_info` reads `GIT_SHA`, which Render does not set, so today it reports "Git SHA not available". Pointing the plugin's `git_sha_mfa` at `RENDER_GIT_COMMIT` fixes this with one option.

Anything not called out above stands as recommended.

## Signals compared

| Signal | Says finished? | Says succeeded? | Plan needed | Can start a run of |
| --- | --- | --- | --- | --- |
| Render deploy API, polled | Yes, `finishedAt` | Yes, status `live`, `build_failed`, `update_failed`, `pre_deploy_failed`, or `canceled` | Any, with an API key | Anything that can poll: an Action, a cron job, a routine |
| Render events API, polled | Yes, `deploy_ended` | Yes, `deployStatus` `succeeded`, `failed`, or `canceled`, plus a reason | Any | Same as above |
| Render webhook | Yes, `deploy_ended` | Yes, `data.status` | Pro or higher | A relay you host, which then calls a routine or GitHub |
| Render notification | Failures always, success on Slack only | Yes | Any | Nothing an agent can subscribe to directly |
| GitHub deployment status | Yes | Yes, `success` or `failure` | Render's GitHub App | A GitHub Action, through `deployment_status`. Not posted for `flick` today |
| GitHub commit status or check run | No | No | n/a | Render posts neither for `flick` |

### Render deploy and events APIs

The [List deploys](https://api-docs.render.com/reference/list-deploys) endpoint filters by `status`, `createdAfter`, and `finishedAfter`, and each deploy carries its commit SHA, `trigger`, and status. The status set is `created`, `queued`, `build_in_progress`, `update_in_progress`, `live`, `deactivated`, `build_failed`, `update_failed`, `canceled`, `pre_deploy_in_progress`, and `pre_deploy_failed`. The events list adds `deploy_ended` with a reason, plus `server_failed` and `commit_ignored`, which tell an agent why a service went down or why a push made no deploy.

The [rate limits](https://api-docs.render.com/reference/rate-limiting) are 400 per minute for most `GET` calls and 30 per minute for logs. A Render API key gives access to "*all* workspaces you belong to", per the [authentication docs](https://api-docs.render.com/reference/authentication), and the docs mention no read-only key. The key's owner belongs to workspaces unrelated to Flick, so the key's blast radius is wider than Flick. Any design must keep it in a secret store and say so.

A poller must handle three cases the real data shows:

- **Superseded deploys.** On 2026-10-12, commit `93ee530` started two deploys, one from `new_commit` and one from `blueprint_sync`. Render canceled the first. Wait for the newest deploy for the commit, and do not report `canceled` as a failure.
- **Pushes with no deploy.** `render.yaml` ignores `docs/**`, `.github/**`, `*.md`, and other paths, so a push that touches only those produces no deploy. Treat a `commit_ignored` event, or no deploy after a few minutes, as "nothing to verify".
- **Deploys that race CI.** `autoDeployTrigger: commit` deploys on push without waiting for checks. The `a11112b` deploy started at 15:57:02, before its Build and Test check finished at 15:57:55.

### Render webhooks

Per [Render's webhook docs](https://render.com/docs/webhooks), "Webhooks require a Pro plan or higher." A Pro workspace gets one destination URL, and Scale or Enterprise get up to 100. Only workspace admins create them, in the dashboard under Integrations > Webhooks. The docs describe no API for creating them, and webhooks filter by event type, not by service. A `deploy_ended` for `flick-grafana` reaches the same URL as one for `flick`.

Payloads are thin: `type`, `timestamp`, `data.id`, `data.serviceId`, `data.serviceName`, and `data.status` for `deploy_ended` and a few others. Delivery follows the Standard Webhooks spec, with `webhook-id`, `webhook-timestamp`, and `webhook-signature` headers. The receiver must answer 2xx within 15 seconds. Render retries up to 8 times over about 33 hours, then disables the webhook. The docs describe no custom headers.

Render's docs do not state the Flick workspace's plan, and the MCP tools do not return it. The evidence points to Pro or higher: the logs API returned `flick` logs from 2026-10-01, 12 days back, and [Render's logging docs](https://render.com/docs/logging) give Hobby 7 days of retention. Response-latency metrics, which [need Pro](https://render.com/docs/service-metrics), also came back. Confirm on the workspace's Billing page before building on webhooks.

### Render notifications

[Notifications](https://render.com/docs/notifications) go to email, Slack, or both. Email and Slack both carry build and deploy failures. "Successful deploys going live" goes to Slack only. An agent cannot subscribe to either channel without another integration, so notifications are a human signal.

### GitHub deployment statuses

Render's GitHub App creates a GitHub deployment per deploy for `flick-grafana` and `flick-prometheus`. The deployment for `flick-grafana` at `a11112b` received `in_progress` and then `success`, with `environment_url` set to the service URL and `log_url` pointing at the Render deploy page. GitHub Actions can [run on `deployment_status`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#deployment_status), except when the state is `inactive`. Render's docs do not mention this feature. Render's [feature request board](https://feedback.render.com/features/p/github-deployments-integration) still lists GitHub deployment status updates as planned, so treat the behavior as undocumented.

Render posts no commit status and no check run on Flick commits. All six check runs on `a11112b` come from GitHub Actions.

## What can start a run

| Runner | Poll Render API | Render webhook | GitHub `deployment_status` |
| --- | --- | --- | --- |
| GitHub Action | Yes, triggered by `push` to `main`. A `schedule` also works, at most every 5 minutes | Only through a relay that calls `repository_dispatch` | Yes, but `flick` gets no deployments today |
| Claude Code routine | Yes, on its hourly-minimum schedule | Only through a relay that calls `/fire` with the bearer token | No. GitHub triggers support pull request and release events only |
| Render cron job | Yes, on any cron schedule, at the cost of another service | No | No |

A routine's API trigger is a `POST` to `/fire` with `Authorization: Bearer`, an `anthropic-beta` header, and an optional `text` field. The `text` arrives wrapped as untrusted data, so the routine's prompt must say to act on it. Each routine allows 30 fires an hour, and each account allows 100. A GitHub Action holding the routine token as a secret can make that call after its poll ends, which makes the Action a ready-made relay without new hosting.

A routine includes all of a connector's tools. The Render connector includes `trigger_deploy` and `update_environment_variables`, so a routine given the Render connector can deploy and change secrets. The [Render MCP docs](https://render.com/docs/mcp-server) say "The MCP server supports potentially destructive operations." The map rules out agents that deploy or change production settings, so a deploy agent should call the REST API with a narrow script instead, or the guardrails ticket must address this.

## What an agent can check after a deploy

| Check | Access | What it tells the agent |
| --- | --- | --- |
| `GET https://rankedvote.app/` | Public | The app serves pages. Returned 200 in 0.38 s on 2026-10-13 |
| A known public ballot page or results page | Public | LiveView pages render and reach the database |
| `GET https://rankedvote.app/metrics` | Basic auth, `flick-metrics` and `METRICS_AUTH_PASSWORD` | PromEx counters for HTTP status codes, Ecto queries, LiveView, BEAM, uptime, and vote durations. Point-in-time only, so the agent compares two scrapes itself |
| Render events API | API key or MCP | `deploy_ended` status and reason, and any `server_failed` or `server_restarted` after the deploy |
| Render logs API | API key or MCP, 30 per minute | Boot lines such as "Migrations already up", error-level app logs, and request logs with status codes |
| Render metrics API | API key or MCP | HTTP request counts by status code, latency quantiles, memory, and CPU, at 30-second or coarser resolution |

Production Prometheus is a private service and Grafana needs a login, so an agent cannot query history. The `/metrics` endpoint and Render's metrics API are the substitutes. Render's request-count metric split by `statusCode` is the cheapest way to spot a rise in 5xx after a deploy. Production Tempo is not in `render.yaml`, so traces are not an option yet.

An external monitor already probes Flick. Request logs show `HEAD /` from `updown.io daemon 2.11`, which nothing in the repo configures.

Two small changes would make these checks stronger. Both are outside this research's scope.

- **Set `healthCheckPath` on `flick`.** [Render's health checks](https://render.com/docs/health-checks) default to a TCP probe, and a new instance passes if it accepts a connection within five seconds. An HTTP path that touches the database would let Render itself fail a broken deploy, and keep the old instance serving.
- **Report the running commit.** Render sets `RENDER_GIT_COMMIT` at build time and runtime, per its [environment variable docs](https://render.com/docs/environment-variables). PromEx's Application plugin reads `GIT_SHA` by default and accepts a `git_sha_mfa` option to read something else.

## Observed deploys

The last five `flick` deploys, from `list_deploys`:

| Deploy created (UTC) | Commit | Trigger | Final status | Duration |
| --- | --- | --- | --- | --- |
| 2026-10-12 15:57 | `a11112b` | `new_commit` | `live` | 1 min 46 s |
| 2026-10-12 00:10 | `93ee530` | `blueprint_sync` | `deactivated` (was live) | 3 min 0 s |
| 2026-10-12 00:10 | `93ee530` | `new_commit` | `canceled` | 1 s |
| 2026-10-11 23:42 | `dbdbb84` | `new_commit` | `deactivated` (was live) | 1 min 48 s |
| 2026-10-11 17:23 | `213fa67` | `new_commit` | `deactivated` (was live) | 2 min 6 s |

`deactivated` means a later deploy replaced it, so a poller must read the status soon after `finishedAt`, or use the `deploy_ended` event, which keeps `succeeded`.
