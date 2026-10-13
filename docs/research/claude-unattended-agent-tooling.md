# Claude Code routines fit Flick's first agents best, with the GitHub Action as the fallback when an agent needs a tool allowlist

Researched 2026-10-13 for [issue #286](https://github.com/zorn/flick/issues/286), under the map [#285](https://github.com/zorn/flick/issues/285). Sources are the Claude Code docs at code.claude.com, the Claude Platform docs at platform.claude.com, the [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) repository (latest release v1.0.248, 2026-10-09), and Render's docs. Routines and Managed Agents are both in preview or beta, so expect details to move. Nothing here was run end to end; the cost figures are list-price arithmetic, not measurements.

## Answer

1. **Four Claude tools run an agent with nobody at the keyboard.** They are Claude Code routines, the `claude-code-action` GitHub Action, the Claude Agent SDK on infrastructure you host, and Claude Managed Agents. Desktop scheduled tasks and `/loop` do not qualify: a Desktop task fires only "while the desktop app is running and your computer is awake," and `/loop` tasks are session-scoped ([Desktop scheduled tasks](https://code.claude.com/docs/en/desktop-scheduled-tasks), [scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks)). Claude Code on the web is the runtime that routines use, not a separate trigger.
2. **Routines are the cheapest and fastest start for Flick.** They support cron, an HTTP API trigger, and GitHub pull request and release events. They bill against the Claude subscription, so a run costs no extra money until you hit the plan's usage limit ([routines](https://code.claude.com/docs/en/routines)). They can use the Render connector already on the claude.ai account.
3. **Routines have no per-tool allowlist for connectors.** "Claude can use every tool from an included connector, including writes, without asking for permission during a run" ([routines](https://code.claude.com/docs/en/routines#create-from-the-web)). The Render MCP server can trigger deploys and replace environment variables ([Render MCP](https://render.com/docs/mcp-server)). The map rules out agents that deploy or change production settings, so this gap matters. A committed `.claude/settings.json` deny rule applies in cloud sessions ([cloud environments](https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup)), but I have not confirmed that deny rules match claude.ai connector tools in a routine. Test this before a routine gets the Render connector.
4. **The GitHub Action is the fallback when an agent needs a hard tool allowlist.** It runs on any GitHub event, including `schedule`, `workflow_dispatch`, and `repository_dispatch`. Tools are off until `--allowedTools` grants them, so a Render MCP server can be limited to its read tools ([GitHub Actions](https://code.claude.com/docs/en/github-actions#run-on-a-schedule)). Flick is a public repository, so the runner minutes are free. It cannot use claude.ai connectors, so Render needs its own API key in a GitHub secret.
5. **Managed Agents give the strongest controls, at API prices.** They offer per-tool enable flags on MCP servers, a hard dollar budget per session, cron deployments, and vault-held secrets that never enter the sandbox ([MCP connector](https://platform.claude.com/docs/en/managed-agents/mcp-connector), [budgets](https://platform.claude.com/docs/en/managed-agents/budgets), [vaults](https://platform.claude.com/docs/en/managed-agents/vaults)). There is no GitHub event trigger, so something else must call the API. A run bills API tokens plus $0.08 per session-hour ([pricing](https://platform.claude.com/docs/en/about-claude/pricing#claude-managed-agents-pricing)).
6. **The Agent SDK adds no capability Flick needs.** It requires an API key and hosting you build yourself ([SDK quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart), [hosting](https://code.claude.com/docs/en/agent-sdk/hosting)). The GitHub Action already wraps the same Claude Code runtime with the trigger and hosting solved.
7. **Every Render path holds a full-access credential.** Render's docs describe no read-only or service-scoped API key, and the MCP server acts on whatever the key or OAuth login can reach ([Render API](https://render.com/docs/api), [Render MCP](https://render.com/docs/mcp-server)). The guardrails grilling in [#289](https://github.com/zorn/flick/issues/289) should treat tool filtering, not key scope, as the only Render boundary.

## Comparison

| | Routines | GitHub Action | Agent SDK | Managed Agents |
| --- | --- | --- | --- | --- |
| Runs on | Anthropic cloud session | GitHub-hosted runner | Your container | Anthropic sandbox |
| Cron | Yes, minimum one hour | Yes, GitHub `schedule` | Your scheduler | Yes, minute granularity |
| Webhook or API | Yes, `/fire` with a bearer token | Yes, `repository_dispatch` or `workflow_dispatch` | Your endpoint | Yes, create a session or run a deployment |
| GitHub events | PR and release only | Any workflow event | Your webhook receiver | None built in |
| Secrets | Network secrets (Pro, Max) or plain env vars | GitHub Actions secrets | Your secret manager | Vaults |
| Render MCP | claude.ai connector, or `.mcp.json` | `--mcp-config` with an API key | `mcpServers` option | `mcp_servers` with a vault credential |
| Per-tool limits | Repo permission rules only; unconfirmed for connectors | `--allowedTools` | `allowedTools` | `enabled` per tool, plus `always_ask` |
| Writes to GitHub as | You | `claude[bot]` (the Claude GitHub App) | Whatever token you give it | The fine-grained PAT you supply |
| Cost per run | Subscription usage; overage only with usage credits | API tokens or subscription; runner minutes free on public repos | API tokens plus hosting | API tokens plus $0.08 per session-hour |

## Claude Code routines

A routine is "a prompt, one or more repositories, and a set of connectors, packaged once and run automatically" on Anthropic's cloud ([routines](https://code.claude.com/docs/en/routines)). Routines are in research preview and available on Pro, Max, Team, and Enterprise. Create them at claude.ai/code/routines or with `/schedule` in the CLI.

**Triggers.** A routine takes any mix of three triggers.

- A schedule runs hourly, daily, weekdays, weekly, or once at a set time. `/schedule update` sets a custom cron expression, but "the minimum interval is one hour." Runs set exactly on the hour can start several minutes late.
- An API trigger gives the routine a `POST .../v1/claude_code/routines/<id>/fire` endpoint with its own bearer token. The body takes an optional `text` field, which arrives wrapped as untrusted data. The prompt must opt in to acting on it, for example "Investigate the alert described in the routine-fire-payload block." The endpoint needs the `experimental-cc-routine-2026-04-01` beta header.
- A GitHub trigger reacts to pull request or release events, with filters on author, branch, labels, draft, and merged state. It needs the Claude GitHub App installed. Issue events, `push`, and `deployment_status` are not on the list.

**Secrets.** Each routine runs in a cloud environment. Environment variables there are "visible to anyone who uses the environment." On Pro and Max plans, a network secret holds an API key that "Anthropic's agent proxy adds … to requests for the hosts you list, after each request leaves the session's VM, so the key itself stays outside the VM." Team and Enterprise plans do not have network secrets yet ([cloud environments](https://code.claude.com/docs/en/cloud-environments#add-network-secrets)). GitHub needs no secret, because a GitHub proxy authenticates as your connected account.

**MCP and Render.** Routines use the claude.ai connectors on your account, and every one is included by default. Connector traffic goes through Anthropic's servers, so the environment's network allowlist does not need the connector's host. A server in a committed `.mcp.json` also loads in a single-repository routine. `claude mcp add` servers on your laptop do not ([routines](https://code.claude.com/docs/en/routines#connectors)).

**Writes.** A routine clones each repository and pushes to `claude/`-prefixed branches. "Anything a routine does through your connected GitHub identity or connectors appears as you: commits and pull requests carry your GitHub user." `gh api` calls work through the GitHub proxy, so issues and comments are reachable ([cloud environments](https://code.claude.com/docs/en/cloud-environments#github-proxy)). Use branch protection to stop pushes to `main`.

**Cost.** "Routines draw down subscription usage the same way interactive sessions do." Separate hourly caps apply: 100 scheduled runs per account, and 30 API or **Run now** fires per routine. Past the subscription limit, runs are rejected unless usage credits are on ([routines](https://code.claude.com/docs/en/routines#usage-and-limits)). The real cost is that routine runs share the usage window with interactive work.

**Flick notes.** Cloud sessions pre-install PostgreSQL 16 but not Elixir, so an agent that runs `mix` needs a setup script. The result is cached for about seven days ([cloud environments](https://code.claude.com/docs/en/cloud-environments#setup-scripts)). A green run status "does not mean the task in your prompt succeeded," so the reporting channel cannot rely on it.

## The `claude-code-action` GitHub Action

The action "runs Claude Code inside your repository's workflows" ([GitHub Actions](https://code.claude.com/docs/en/github-actions)). With no `prompt` input, it answers `@claude` mentions. With a `prompt` input, it runs in automation mode on whatever event starts the workflow.

**Triggers.** Any GitHub Actions event works, including `schedule` cron, issue and PR events, `workflow_dispatch`, and `repository_dispatch` for an external webhook. GitHub runs scheduled workflows only from the default branch. In public repositories, GitHub disables a schedule after 60 days without repository activity. The action rejects bot actors unless they are listed in `allowed_bots`, and that check covers scheduled runs.

**Secrets.** The model credential is a repository secret: `ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`, which bills the subscription. Workload identity federation can replace the stored key with a GitHub OIDC exchange. Other credentials, such as a Render API key, are ordinary Actions secrets passed to the step.

**MCP and Render.** Pass servers with `--mcp-config` in `claude_args`. The subscription token "can only make model requests, so it can't … fetch claude.ai connectors," so the claude.ai Render connector is not available ([authentication](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token)). Use Render's hosted server at `https://mcp.render.com/mcp` with an `Authorization: Bearer` API key ([Render MCP](https://render.com/docs/mcp-server)).

**Tool limits.** "For a plain-text prompt, Claude has no shell or GitHub API access until you grant the tools the prompt needs, with `--allowedTools`." This default-deny shape is the main reason to pick the action for any agent that holds a Render key.

**Writes.** The Claude GitHub App has read and write access to contents, issues, and pull requests. The action can comment, push branches, and open PRs, and the work appears as the app, not as you. Grant the workflow job only the `permissions:` it needs.

**Cost.** Each run uses GitHub Actions minutes and model tokens. Standard GitHub-hosted runners are free for public repositories ([GitHub billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions)). Tokens bill to the API key, or to the subscription with an OAuth token. Cap a run with `--max-turns` and a job `timeout-minutes`.

## Claude Agent SDK

The SDK is the Claude Code agent loop as a Python or TypeScript library ([overview](https://code.claude.com/docs/en/agent-sdk/overview)). It has no trigger of its own; you bring the scheduler, webhook receiver, and container. Anthropic's hosting guide recommends one ephemeral container per task and "a proxy that injects API keys after the request leaves the container" ([hosting](https://code.claude.com/docs/en/agent-sdk/hosting)). MCP servers, `allowedTools`, and permission modes match the CLI.

The quickstart authenticates with an API key and warns that Anthropic "does not allow third party developers to offer claude.ai login or rate limits" for SDK products ([quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart)). Plan on API billing. Results report `total_cost_usd` per run ([headless](https://code.claude.com/docs/en/headless)). For Flick, the GitHub Action already gives this runtime a host and triggers, so the SDK only pays off if an agent needs a long-lived process.

## Claude Managed Agents

Managed Agents are "a pre-built, configurable agent harness that runs in managed infrastructure," in beta behind the `managed-agents-2026-04-01` header and enabled for all API accounts ([overview](https://platform.claude.com/docs/en/managed-agents/overview)). You define an agent, an environment, and then start sessions.

**Triggers.** A session starts from an API call, or from a scheduled deployment with a POSIX cron expression and an IANA time zone, at minute granularity. Execution has jitter of up to 15% of the interval, capped at nine minutes ([scheduled deployments](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)). Webhooks are outbound only: they report session state changes to you ([webhooks](https://platform.claude.com/docs/en/managed-agents/webhooks)). A GitHub event or Render alert needs a relay, such as a GitHub workflow, that calls the API.

**Secrets.** Vaults hold MCP credentials (`mcp_oauth`, `static_bearer`) keyed by server URL, and `environment_variable` credentials that sit in the sandbox as "an opaque placeholder" and are substituted only on requests to `allowed_hosts`. Vaults are workspace-scoped, so any API key in the workspace can use them ([vaults](https://platform.claude.com/docs/en/managed-agents/vaults)).

**MCP and Render.** Any remote MCP server URL works, with its token from a vault. Each MCP toolset can set `default_config.enabled: false` and then enable named tools only. MCP tools default to `always_ask`, so an unattended agent must set `always_allow` on the tools it keeps ([MCP connector](https://platform.claude.com/docs/en/managed-agents/mcp-connector), [permission policies](https://platform.claude.com/docs/en/managed-agents/permission-policies)).

**Writes.** A session mounts a GitHub repository with a token you supply and uses the GitHub MCP server to open PRs. The docs advise a fine-grained personal access token "with minimum required permissions" ([GitHub](https://platform.claude.com/docs/en/managed-agents/github)). Issues and comments come through the same MCP server.

**Cost.** Tokens bill at Messages API rates, plus $0.08 per session-hour while the session is `running`; idle time is free ([pricing](https://platform.claude.com/docs/en/about-claude/pricing#claude-managed-agents-pricing)). A session or deployment can carry a hard `max_list_cost` budget, and the session pauses when it reaches the cap ([budgets](https://platform.claude.com/docs/en/managed-agents/budgets)). Managed Agents are not eligible for Zero Data Retention.

## What a run costs

The API-billed options price a run by tokens. As an illustration, take a 20-minute run of 30 turns that reads about 1M input tokens in total, 90% of them from cache, writes 100K tokens to cache, and outputs 20K tokens. At [list prices](https://platform.claude.com/docs/en/about-claude/pricing), that run costs about $0.55 on Sonnet 5.5 and about $1.10 on Opus 5.5. Managed Agents add about $0.03 of runtime. A daily agent at those rates costs roughly $15 to $35 a month. A run that reads large Render log pages or many traces can cost several times more, so the cost ceiling in the map should be measured with `total_cost_usd` or a Managed Agents budget on the first real agent.

Routines and the action with an OAuth token cost nothing extra until the subscription's usage window runs out. They then stop or draw usage credits, and they compete with interactive work for the same window.

## Recommendation for the map

Build the first agent as a routine if it needs no Render write protection, for example a docs drift watcher that reads the repository and opens issues. Build it on the GitHub Action if it needs Render, because `--allowedTools` can hold it to Render's read tools. Revisit Managed Agents when an agent needs a hard spend cap or a sub-hourly schedule. Before any routine gets the Render connector, test whether a committed deny rule blocks a claude.ai connector tool such as `trigger_deploy` in a cloud session.
