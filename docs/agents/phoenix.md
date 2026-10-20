# Phoenix

## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/", FlickWeb do
        pipe_through :browser

        live "/", IndexLive, :index
      end

  the IndexLive route would point to the `FlickWeb.IndexLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
