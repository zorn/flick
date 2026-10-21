# Hosting

Flick runs on Render, in workspace `tea-cr5894tumphs73e1ml0g` as the web service `flick` (`srv-cr590j08fa8c73acf5u0`). Pass that workspace ID to the Render tools rather than asking which workspace to use. The service is managed by a Blueprint, so `render.yaml` is the source of truth for its settings. A dashboard change that `render.yaml` does not carry is overwritten on the next sync.

These IDs are identifiers, not credentials. Keep a Render API key and the service's deploy hook URL out of git, in Render and your local environment, because the hook URL embeds a key that triggers deploys.

The database `flick_prod` accepts no external connections, because `render.yaml` sets an empty IP allow list. Services in the workspace connect over the private network, so they are not affected. The Render MCP tool `query_render_postgres` and `render psql` connect over the external URL, so they fail. Keep `render.yaml`'s allow list empty, because the repo is public.

Check behavior against local data, such as `mix run priv/repo/seeds.exs`, rather than the production database. When a task needs production data, ask the user for a copy of the database. Do not reach the data yourself through a remote shell, `render ssh`, or an allow-list entry. The user downloads a backup from the database's Recovery page in the Render dashboard, and the download does not go through the allow list.

## Paraxial

Flick runs the Paraxial agent in dev and prod, on the free tier. In prod it runs Exploit Guard in monitor mode, and its alerts appear in Paraxial's dashboard, not in ntfy, where Grafana's alerts go. The agent reads `PARAXIAL_API_KEY` from the environment, which is the only place that key belongs.

Each boot calls paraxial.io from a background task, even without a key. A failed call is silent and never blocks boot, so working offline is fine. With a key set, each boot also uploads an App Audit, and a failed upload logs `[Paraxial] App Audit upload failed`. The dependency leaves out `:test`, so tests and CI make no network call.

The free tier allows five code scans a month, and `mix paraxial.scan` spends one each time. CI already runs the same three tools, so don't add the scan to CI or run it without being asked.
