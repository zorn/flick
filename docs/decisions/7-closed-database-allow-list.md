# Decision: Closed Database Allow List

`flick_prod` accepts no external connections. `render.yaml` sets
`ipAllowList: []`, and the field stays explicit, because an omitted field keeps
the database's existing entries. Every service in the workspace connects over
the private network, which the allow list does not govern. Before this change,
the password was the only barrier between the internet and the database.

There is no standing entry for a home IP. `render.yaml` is public, so a
committed entry would publish the address. An entry added in the dashboard
conflicts with the Blueprint, and it does not cover any other network. To
connect from a laptop, add your current IP for one session and remove it by
hand. A Blueprint sync overwrites the entry, but a sync may not run for weeks.

The cost is tooling that connects over the external URL. `render psql` and the
Render MCP tool `query_render_postgres` fail without a temporary entry, and the
hosted MCP server connects from an address we do not control. The first way to
reach the data is remote IEx from the `flick` service's Shell tab, which uses
the private network. A local copy comes from a backup downloaded on the
database's Recovery page.

Context: [#296](https://github.com/zorn/flick/issues/296).
