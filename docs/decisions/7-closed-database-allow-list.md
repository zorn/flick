# Decision: Closed Database Allow List

`flick_prod` accepts no external connections, because `render.yaml` sets
`ipAllowList: []`. The field stays explicit, because an omitted field keeps the
database's existing entries. Every service in the workspace connects over the
private network, which the allow list does not govern. Before this change, the
password was the only barrier between the internet and the database.

There is no standing entry for a home IP. `render.yaml` is public, so a
committed entry would publish the address. An entry added in the dashboard
conflicts with the Blueprint. A home entry also does not help when you connect
from another network. To connect from a laptop, add an entry for one session
and remove it by hand. A Blueprint sync overwrites dashboard changes, but
Render's docs do not say whether a sync runs when `render.yaml` is unchanged.

The cost is tooling that connects over the external URL. A temporary entry
restores `render psql`. It does not restore the Render MCP tool
`query_render_postgres`, because the hosted MCP server connects from an address
we do not control. AGENTS.md lists the preferred ways to reach the data.

Context: [#296](https://github.com/zorn/flick/issues/296).
