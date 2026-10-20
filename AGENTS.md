Flick is a ranked voting web application built with Elixir and Phoenix LiveView. It lets users create ballots and capture ranked votes without requiring accounts. The app module is `Flick` and the web module is `FlickWeb`.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Add every new CI check to the `precommit` alias in `mix.exs`, unless it needs a tool that isn't a Mix task. `precommit` mirrors CI's Mix checks, so a green local run predicts a green pull request
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

## Elixir

- To use the result of an `if`, `case`, or `cond`, bind the whole expression: `socket = if connected?(socket), do: assign(socket, :val, val), else: socket`. A variable rebound inside the block is lost when the block ends.
- Put one module in each file.
- Read struct fields with dot syntax, such as `ballot.question_title`. Structs do not implement `Access`, so `ballot[:question_title]` fails.
- Use Elixir's `Date`, `Time`, `DateTime`, and `Calendar` for date and time work. Add a dependency only when asked.
- When one dependency misbehaves, clean only that one with `mix deps.clean <name>`. A full `--all` clean is almost never needed.

## Task guides

The files under `docs/agents/` hold guidance that only some tasks need. Read the matching file before you start the work it covers. When a task spans several areas, read each file that applies.

- Before you change a LiveView, a function component, a HEEx template, or a form, read [`docs/agents/liveview.md`](docs/agents/liveview.md).
- Before you write or change a test, read [`docs/agents/testing.md`](docs/agents/testing.md).
- Before you change a schema, a changeset, a query, or a migration, read [`docs/agents/ecto.md`](docs/agents/ecto.md).
- Before you change the router, a controller, or an HTML view module, read [`docs/agents/phoenix.md`](docs/agents/phoenix.md). For a `live` route, also read [`docs/agents/liveview.md`](docs/agents/liveview.md). For a route under `/admin`, also read [`docs/agents/observability.md`](docs/agents/observability.md), which says where LiveDashboard must stay.
- Before you change CSS, JavaScript under `assets/`, or the look of a page, read [`docs/agents/frontend.md`](docs/agents/frontend.md).
- Before you change metrics, traces, alerts, `instrumentation/`, or `rel/env.sh.eex`, read [`docs/agents/observability.md`](docs/agents/observability.md). Also read it before you inspect a running node, or to check how a change affects latency or query counts.

## Hosting

Flick runs on Render, in workspace `tea-cr5894tumphs73e1ml0g` as the web service `flick` (`srv-cr590j08fa8c73acf5u0`). Pass that workspace ID to the Render tools rather than asking which workspace to use. The service is managed by a Blueprint, so `render.yaml` is the source of truth for its settings. A dashboard change that `render.yaml` does not carry is overwritten on the next sync.

These IDs are identifiers, not credentials. Never commit a Render API key or the service's deploy hook URL, since the hook URL embeds a key that triggers deploys.

The database `flick_prod` accepts no external connections, because `render.yaml` sets an empty IP allow list. Services in the workspace connect over the private network, so they are not affected. The Render MCP tool `query_render_postgres` and `render psql` connect over the external URL, so they fail. A temporary entry restores `render psql`, but not the MCP tool, because the hosted MCP server connects from an address we do not control. To reach production data, use one of these, in order of preference:

- Open a remote IEx shell (see [`docs/agents/observability.md`](docs/agents/observability.md)) and query through `Flick.Repo`, for example `Flick.Repo.query!("SELECT count(*) FROM ballots")`. This uses the private network.
- For a local copy, download a backup from the database's Recovery page in the Render dashboard. The download does not go through the allow list.
- For `psql`, `render psql`, or a GUI client, add an entry for your current IP in the database's Networking settings, connect, and remove the entry when you finish. Do not wait for a Blueprint sync to remove it. A sync overwrites dashboard changes, but Render's docs do not say whether a sync runs when `render.yaml` is unchanged. Never commit an entry to `render.yaml`, because the repo is public.

## Paraxial

Flick runs the Paraxial agent in dev and prod, on the free tier. In prod it runs Exploit Guard in monitor mode, and its alerts appear in Paraxial's dashboard, not in ntfy, where Grafana's alerts go. The agent reads `PARAXIAL_API_KEY` from the environment. Never commit that key.

Each boot calls paraxial.io from a background task, even without a key. A failed call is silent and never blocks boot, so working offline is fine. With a key set, each boot also uploads an App Audit, and a failed upload logs `[Paraxial] App Audit upload failed`. The dependency leaves out `:test`, so tests and CI make no network call.

The free tier allows five code scans a month, and `mix paraxial.scan` spends one each time. CI already runs the same three tools, so don't add the scan to CI or run it without being asked.

## Flick domain knowledge

### Ballot state machine

Ballots move through three states, controlled by `published_at` and `closed_at` timestamps:

- **draft** — `published_at` is nil; ballot can be freely edited
- **published** — `published_at` is set; ballot is read-only, voters can cast votes
- **closed** — `closed_at` is set; voting is stopped, results are final

Many operations gate on state. Always check state before allowing edits or votes. The context functions `publish_ballot/2` and `close_ballot/2` in `Flick.RankedVoting` handle transitions.

### URL slug and secret

Every ballot has two identifiers:

- `url_slug` — public identifier used in all voter-facing URLs (e.g. `/ballot/:url_slug`)
- `secret` — UUID required for admin/edit access (e.g. `/ballot/:url_slug/:secret/edit`)

Always require both `url_slug` and `secret` for any operation that modifies a ballot.

### Weighted votes

Votes have a `weight` field (float, default `1.0`). Results calculations must account for weights — a vote with `weight: 2.0` counts twice. Admins can edit vote weights inline on a published ballot.

### No user authentication

There is no user account system. The `/admin/*` scope is protected by HTTP Basic Auth (credentials from `BASIC_AUTH_ADMIN_USERNAME` / `BASIC_AUTH_ADMIN_PASSWORD` env vars). Ballot-specific edit/admin access is not protected by Basic Auth; it is granted via the ballot's `url_slug` and per-ballot `secret` in routes such as `/ballot/:url_slug/:secret/edit`. Public ballot creation and voting are completely open.

### Markdown safety

The `description` field on ballots accepts user-provided Markdown. Always render it through `Flick.Markdown.render_to_html/1`, which runs MDEx and then sanitizes the output via `HtmlSanitizeEx`. Never render raw user content directly in templates.

### Timezone handling

Flick displays timestamps in the user's local timezone. The timezone string is captured from the browser via `get_connect_params` in LiveView and stored as a socket assign. Always pass `time_zone` through to components that display datetimes and use `Flick.DateTimeFormatter` for formatting. Default to `"UTC"` if not present.

## Project structure

Each module's `@moduledoc` says what it does. All ballot and vote operations go through the context module `Flick.RankedVoting`, in `lib/flick/ranked_voting.ex`.
