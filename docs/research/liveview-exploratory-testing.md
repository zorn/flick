# Exploratory testing for Flick: property tests in CI first, a Playwright-driven agent on a local stack second, and no off-the-shelf LiveView fuzzer

Researched 2026-10-13 for [issue #288](https://github.com/zorn/flick/issues/288), under the map [#285](https://github.com/zorn/flick/issues/285). Versions checked: Phoenix LiveView 1.2.12 and PromEx 1.12.0 (both from `mix.lock`), StreamData 1.4.0, PropCheck 1.5.0, `@playwright/mcp` 0.0.83, PhoenixTest 0.12.1, and PhoenixTest.Playwright 0.18.0. Render, Anthropic, and GitHub facts come from their docs as of the same date.

## Answer

1. **Add StreamData property tests first. They are the cheapest and most reproducible option, and they run in the existing CI job.** They find invariant breaks and crashes in `Flick.RankedVoting` and in the LiveViews, such as a results report that miscounts a weighted vote, or a changeset that passes but then crashes on a database constraint. A failure is shrunk to the smallest input and replays with `mix test --seed N`. CI is free, because the repository is public. StreamData is not yet a dependency.
2. **Build the browser agent as Claude Code plus Playwright MCP, run headless against a local or CI copy of Flick.** It finds a different class of bug: a crash that needs a specific multi-step path, a stale second tab, a browser-sent value, or a JS hook. These are the bugs a real user hits and a property test does not think to try. It is not deterministic. Each crash it finds must become a failing ExUnit test before anyone fixes it. A 30-minute run costs about $1 to $10 in tokens, depending on the model.
3. **Use Playwright MCP, not Claude in Chrome or computer use.** Claude in Chrome needs a person's logged-in Chrome and turns itself off under an API key, so it cannot run in CI. Computer use drives a whole desktop through screenshots, and Anthropic's own docs point web-only tasks to the browser use tool instead. The API's browser use tool works, but it means writing your own agent loop and browser executor, which Claude Code already provides.
4. **No fuzzer for Phoenix or LiveView exists that is worth adopting.** Hex has no LiveView fuzzer. OWASP ZAP can fuzz WebSocket frames, but almost every frame it sends is a malformed LiveView payload. The project already accepts a crash from such a payload, so ZAP finds little that matters. Schemathesis needs an OpenAPI or GraphQL schema, and Flick has neither. gremlins.js does random clicks and typing in a real page, but it was last released in 2020.
5. **Run the fuzzer locally and in GitHub Actions, not on Render.** Render preview environments need a Pro workspace, at $25 a month flat plus per-second compute for every copied service. They also skip `sync: false` secrets such as `SECRET_KEY_BASE`, so Flick needs an extra environment group to boot. Render's simpler single-service pull request previews are worse: they copy `DATABASE_URL`, so a preview writes to the production database unless someone changes it.
6. **Detect crashes from the server, not from the page.** Flick already exports the PromEx counters `flick_prom_ex_phoenix_live_view_handle_event_exception_duration_milliseconds_count` and `..._mount_exception_...`, tagged with module, event, and exception. The server log carries the stack trace. Tempo traces add the request path once the `add-traces` branch merges. The agent should check these after every few actions, because a LiveView crash only shows the user a brief reconnect.

Anything not called out above stands as recommended.

## What each option finds

The three options overlap little. The table summarizes them, and the sections below give the detail.

| | StreamData property tests | Browser agent (Playwright MCP) | Generic fuzzers (ZAP, gremlins.js) |
| --- | --- | --- | --- |
| Bug class | Invariant breaks, crashes on odd but valid input, changeset and database disagreements | Multi-step and multi-tab crashes, browser-sent values, JS hooks, UX dead ends | Malformed frames (ZAP), random UI noise (gremlins.js) |
| Real-user bugs | Yes, if inputs go through `form/3` | Yes, by construction | Rarely for ZAP; sometimes for gremlins.js |
| Where it runs | `mix test`, locally and in CI | Local dev stack, or a CI job with Postgres | Local |
| Reproduction | Shrunk input plus `--seed` | A Playwright trace, then a hand-written failing test | ZAP message log; gremlins.js seed |
| Cost | CI minutes (free here) | About $1 to $10 per 30-minute run | Free |

### StreamData property tests

StreamData generates inputs, runs the property 100 times by default, and on failure shrinks to "the smallest set of values that still reproduces the error" ([ExUnitProperties docs](https://hexdocs.pm/stream_data/ExUnitProperties.html)). Its seed comes from ExUnit, so "the random generation will follow options like `--seed` used in ExUnit to deterministically reproduce tests" (same page). This makes every failure a one-line replay.

Two kinds of property fit Flick:

- **Context properties.** Generate a ballot, a set of possible answers, and votes with ranks and weights. Then assert invariants on `get_ballot_results_report/1`, such as "total weight equals the sum of vote weights" or "the result never raises." Also assert that a changeset that is valid always inserts. That catches the class of bug in the [Ecto length research](ecto-length-counting.md), where a validation and a column count different units.
- **LiveView properties.** Drive a LiveView through `Phoenix.LiveViewTest` with generated form values. Use `form/3`, because "This function is meant to mimic what the user can actually do": it validates the data against the rendered form, and "Invalid data raises an `ArgumentError`" ([LiveViewTest docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)). That keeps the property on payloads a real browser could send, which matches the rule that crafted-payload crashes are acceptable. Prefer `element/3` over raw event names for the same reason ("The `element` style is preferred as much as possible", same page).

When the LiveView raises, the test client exits with the exception and stack trace (`exit({{exception, stack}, ...})` in [`live_view_test.ex`](https://github.com/phoenixframework/phoenix_live_view/blob/v1.2.12/lib/phoenix_live_view/test/live_view_test.ex)), so ExUnit reports the crash and StreamData shrinks the input that caused it.

**Limits.** StreamData has no stateful, model-based testing. Its README says that is a PropEr advantage "since StreamData doesn't support this yet" ([README](https://github.com/whatyouhide/stream_data)). You can still generate a list of actions (publish, vote, close, vote again) and fold over it, but shrinking works on the list, not on a model. PropCheck adds real state-machine testing, but it is GPL-3.0 ([hex.pm](https://hex.pm/packages/propcheck)). Property tests also cannot see JavaScript, browser timing, or anything outside the BEAM.

**Cost.** Only CI time. GitHub Actions is "free ... for public repositories that use standard GitHub-hosted runners" ([GitHub billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)), and `zorn/flick` is public. The existing `build-and-test.yaml` already has a Postgres service, so the properties run in `mix test` with no new job.

### Browser-driving LLM agent

**Playwright MCP is the best fit.** It works from the accessibility tree, not pixels, and runs headless with `--headless` ([README](https://github.com/microsoft/playwright-mcp)). It exposes `browser_console_messages` and `browser_network_requests`, and with `--caps=devtools` it can record a Playwright trace and a video (same README). It is Apache-2.0. The README also notes that coding agents increasingly prefer the token-cheaper Playwright CLI, and keeps MCP for "exploratory automation" and "long-running autonomous workflows." That is this use case.

**How it runs.** Claude Code runs headless with `-p`, loads Playwright MCP through `--mcp-config`, and caps its work with `--max-turns`. The same setup runs in GitHub Actions through `anthropics/claude-code-action`, with `claude_args` and a `prompt` on a `schedule` or `workflow_dispatch` trigger ([Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)). The job starts Postgres, runs `mix phx.server`, and gives the agent `http://localhost:4000` and the dev admin credentials.

**What it finds.** An agent can follow paths a test author did not write. Examples in Flick: open the vote page in two tabs and close the ballot in a third; edit a vote weight inline while a new vote arrives; paste emoji or combining marks into answers; send an odd time zone from the browser; use the back button after publishing. The vote-after-close bug fixed in [#276](https://github.com/zorn/flick/pull/276) is this kind of bug.

**How it reports a crash.** An agent run is not reproducible by rerunning it. The report must carry its own reproduction:

1. The exact steps the agent took, from the Playwright trace (`browser_start_tracing` and `browser_stop_tracing`), viewable with `npx playwright show-trace`.
2. The server-side stack trace from the log, and the matching PromEx exception metric.
3. A failing test that the agent writes from those steps, in `Phoenix.LiveViewTest` or [PhoenixTest](https://hex.pm/packages/phoenix_test). The test is the durable artifact. Add [PhoenixTest.Playwright](https://hexdocs.pm/phoenix_test_playwright/PhoenixTest.Playwright.html) only when the bug needs a real browser, such as a JS hook.

The repository is public, so the agent should not open a public issue with a stack trace for a security-relevant crash. Post it where only the owner reads it, or keep it in the workflow log.

**The other browser options.**

- **Claude in Chrome** runs in a visible Chrome window, needs "A direct Anthropic plan (Pro, Max, Team, or Enterprise)," and stays off under an API key or a `claude setup-token` token "because the browser extension can't authenticate with those credentials" ([Claude Code with Chrome](https://code.claude.com/docs/en/chrome)). It is good for a person-supervised session on a laptop, and cannot run in CI.
- **Computer use** controls a desktop through screenshots of "roughly 1,000–1,800 input tokens each," and its docs say that "for tasks that stay inside webpages, the browser use tool is the better fit" ([computer use tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)). It adds cost and no benefit for a web app.
- **The API browser use tool** (`browser_toolset_20260801`) is GA, but "your application runs every call against its own browser automation" ([browser use tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/browser-use-tool)). Its console and network readers are off by default. Choosing it means building an agent loop with the SDK, which Claude Code plus Playwright MCP already does.

**Cost.** Sonnet 5.5 is $2 per million input tokens, $10 per million output tokens, and $0.10 per million cache hits. Opus 5.5 is double that ([pricing](https://platform.claude.com/docs/en/about-claude/pricing)). This is an estimate, not a measurement: a 30-minute run of about 100 browser steps, with a context that grows to about 60,000 tokens and mostly hits the cache, costs about $2 to $3 on Sonnet 5.5 and $5 to $6 on Opus 5.5. A run with no cache hits, or with screenshots in context, can reach $10 or more. Runs authenticated with `CLAUDE_CODE_OAUTH_TOKEN` draw on the subscription instead of API billing ([Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)).

### Fuzzing tools

- **No LiveView fuzzer exists.** A Hex search for "fuzz," "fuzzing," "liveview fuzz," and "property liveview" on 2026-10-13 returned only fuzzy-string libraries, StreamData, PropEr, and unrelated LiveView packages. A web search found no dedicated tool.
- **OWASP ZAP** can "fuzz WebSocket messages (send lots of invalid or unexpected data to a browser or server)" ([ZAP WebSockets add-on](https://www.zaproxy.org/docs/desktop/addons/websockets/)). A LiveView frame carries a join reference, a topic, and a CSRF-checked session. A generic fuzzer mostly breaks that envelope and finds crashes from crafted payloads, which the project accepts. ZAP is worth a one-off security scan, not a recurring fuzzer.
- **Schemathesis** "tests OpenAPI and GraphQL APIs by generating inputs from your schema" ([README](https://github.com/schemathesis/schemathesis)). Flick has no such API, so it does not apply.
- **gremlins.js** is a MIT "Monkey testing library for web apps" with seedable randomness ([repository](https://github.com/marmelab/gremlins.js)). It sends real clicks and keystrokes, so it can only cause what a user could cause. Its last release is 1.0.0 from April 2020 and its last commit is from March 2023. It could run inside a Playwright test through an init script, which keeps it out of Flick's templates. It is a cheap complement to the agent, not a substitute.
- **Sobelow** is already in `mix precommit`. It is a static security scanner, not a fuzzer, but it covers part of what ZAP would.

## Where it can run, given no staging

| Place | Cost | Fit |
| --- | --- | --- |
| Local dev server and `instrumentation/` stack | Tokens only | Best for supervised runs. Prometheus, Grafana, and Tempo are already there to see crashes. |
| GitHub Actions job with a Postgres service | Free CI on a public repo, plus tokens | Best for scheduled runs. Needs the API key or OAuth token as a repository secret. |
| Render preview environment | $25 a month Pro workspace, plus prorated compute for each copied service | Possible, but the costliest, and needs secret setup. |
| Render pull request (service) preview | Prorated at the base service's rate | Unsafe. It shares the production database by default. |
| Production | n/a | Ruled out by #285, because the agent writes data. |

**Render preview environments.** They "require a Pro workspace plan or higher" ([preview environments](https://render.com/docs/preview-environments)). Pro is "$25/month flat" since Render's 2026 plan change, which moved legacy workspaces on August 1, 2026 ([changelog](https://render.com/changelog/updated-plans-for-render-workspaces)). The Render tools did not show which plan the Flick workspace is on. Each preview copies the whole Blueprint, including the datastores, and copies "do not include data from their corresponding 'base' resource." Resources "are billed the same as other Render services and are prorated by the second," and `previews.expireAfterDays` deletes an idle preview. The docs name no way to leave a service out, so a preview of Flick's Blueprint also copies `flick-prometheus` and `flick-grafana`. Values defined with `sync: false` "are not copied to preview environments." Flick's `SECRET_KEY_BASE` and the Basic Auth password are `sync: false`, so a preview needs a dashboard environment group referenced from `render.yaml` (all quotes from the same page).

**Render pull request previews.** They copy settings from the base service, "This includes environment variables, such as database connection information," and the docs warn to "change environment variables on your preview instance if you want it to use a staging or test database" ([service previews](https://render.com/docs/service-previews)). For Flick, that means `DATABASE_URL` points at `flick_prod`. A fuzzer must never run against one.

## How an agent notices a crash

A LiveView crash shows the user a short reconnect, and the page often recovers, so the page is a poor signal. The server signals are reliable:

- **PromEx metrics.** The `PhoenixLiveView` plugin turns `[:phoenix, :live_view, :mount, :exception]` and `[:phoenix, :live_view, :handle_event, :exception]` into histograms tagged with `event`, `action`, `module`, `kind`, and `reason` ([plugin source, 1.12.0](https://github.com/akoutmos/prom_ex/blob/1.12.0/lib/prom_ex/plugins/phoenix_live_view.ex)). In Flick these are `flick_prom_ex_phoenix_live_view_handle_event_exception_duration_milliseconds_count` and its `mount` twin. The plugin marks `handle_params` and LiveComponent exceptions as "Coming soon," so those crashes do not appear. LiveView emits those events too ([LiveView telemetry](https://hexdocs.pm/phoenix_live_view/telemetry.html)). HTTP 500s show in `flick_prom_ex_phoenix_http_requests_total` by `status`.
- **The server log.** It carries the stack trace for every crash, including `handle_params`. The agent should read it after each action burst.
- **Tempo traces.** These tie a crash to the route and the event. They exist on the `add-traces` branch, which is not yet on `main`.

A simple loop works: act for a few steps, then query the exception counters and scan the log for `** (`, and stop to write a reproduction when either changes.
