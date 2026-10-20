# Phoenix

- A router `scope` prefixes its alias onto every route inside it. Inside `scope "/", FlickWeb`, write `live "/ballots", Ballots.IndexLive`, which points to `FlickWeb.Ballots.IndexLive`.
- Render HTML with function components in a module that calls `use FlickWeb, :html`, as `FlickWeb.ErrorHTML` does.
