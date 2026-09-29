# Module Boundaries

Flick uses the [`boundary`](https://hexdocs.pm/boundary) library to keep its domain contexts isolated from one another and from the web layer. This document explains the rule, how the boundaries are arranged, and how a new context declares its own. [Decision 6](decisions/6-module-boundaries.md) records why Flick adopted it.

## The rule

> Call sites must go through a context's public API module. The context's internals are off-limits from the outside.

Without enforcement, nothing stops a LiveView from querying `Flick.Repo` directly or calling a helper buried inside a context. That couples the caller to an implementation detail, so a later change to the context breaks call sites it never promised to support.

Boundary turns the rule into a compile-time check. Each boundary lists the boundaries it may call (`deps`) and the modules of its own that others may call (`exports`). A reference that breaks either list is a compiler warning. `mix precommit` and CI compile with `--warnings-as-errors`, so the warning fails the build.

## The boundaries in this app

Every module belongs to exactly one boundary, chosen by its name. Each boundary declares itself with `use Boundary` in its root module.

| Boundary | Declared in | Exports | May depend on |
|---|---|---|---|
| `Flick` | `lib/flick.ex` | — | — |
| `Flick.RankedVoting` | `lib/flick/ranked_voting.ex` | `Ballot`, `Vote`, `PossibleAnswer`, `RankedAnswer` | `Flick.Repo` |
| `Flick.Repo` | `lib/flick/repo.ex` | — | — |
| `Flick.Markdown` | `lib/flick/markdown.ex` | — | — |
| `Flick.DateTimeFormatter` | `lib/flick/date_time_formatter.ex` | — | — |
| `FlickWeb` | `lib/flick_web.ex` | `Endpoint`, `Telemetry` | `Flick.RankedVoting`, `Flick.Markdown`, `Flick.DateTimeFormatter` |
| `Flick.Application` | `lib/flick/application.ex` | — | `Flick.Repo`, `FlickWeb` |
| `Storybook` | `lib/storybook.ex` | (checks off) | (checks off) |

A boundary's root module is always callable by a boundary that depends on it. That module is the public API. `exports` only adds more modules to the public surface. For `Flick.RankedVoting`, those are the schemas that LiveViews build and pattern-match. `EmbedParams` is an implementation module, so it stays private.

The root `Flick` boundary exports nothing, and nothing depends on it. It holds `Flick.Mailer`, `Flick.NameGenerator`, and `Flick.Release`, which no other boundary may call.

A boundary can depend only on a sibling, its parent, or a dependency of an ancestor, and it sees only what that boundary exports. A module left inside the root `Flick` boundary is therefore unreachable. That is why `Flick.Repo`, `Flick.Markdown`, and `Flick.DateTimeFormatter` are top-level leaf boundaries: they depend on nothing, and other boundaries can list them in `deps`. The web layer lists the two formatting helpers but not `Flick.Repo`, which is how "the web layer never touches the database" is enforced.

`Flick.Application` is top-level so that it can depend on both `Flick.Repo` and `FlickWeb` to build the supervision tree.

### Alias references are checked too

`mix.exs` sets `boundary: [default: [check: [aliases: true]]]`. By default, Boundary checks only function calls and struct expansions. A module named as a plain value, such as a Gettext backend in `use Gettext, backend: FlickWeb.Gettext`, escapes that check. With alias checks on, a domain module that names any `FlickWeb` module fails the build.

### Storybook and test helpers

phoenix_storybook compiles the files under `storybook/` into `Storybook.*` modules. `lib/storybook.ex` claims them in a `Storybook` boundary with its checks off, because they are dev scaffolding and not domain code.

The test helpers in `test/support/` are top-level boundaries with their own `deps`, so that no application boundary needs a test-only dependency.

| Boundary | May depend on |
|---|---|
| `Flick.DataCase` | `Flick.Repo` |
| `FlickWeb.ConnCase` | `Flick.DataCase` |
| `Support.Fixtures.BallotFixture` | `Flick.RankedVoting` |

These modules exist only in the `:test` build, so `mix boundary.spec` in `:dev` does not show them. Test files (`*_test.exs`) are not compiled into the project, so Boundary does not check them.

## Adding a new context

Follow the `Flick.RankedVoting` pattern.

1. Create the context's public API module, for example `lib/flick/accounts.ex`.
2. Declare it as a top-level boundary, and export only the data types that cross the boundary:

   ```elixir
   defmodule Flick.Accounts do
     use Boundary, top_level?: true, deps: [Flick.Repo], exports: [User]
   end
   ```

3. Add it to the `deps` of each boundary that calls it, for example in `lib/flick_web.ex`:

   ```elixir
   use Boundary,
     deps: [Flick.RankedVoting, Flick.Accounts, Flick.Markdown, Flick.DateTimeFormatter],
     exports: [Endpoint, Telemetry]
   ```

4. If the context needs a module from the root `Flick` boundary, such as `Flick.Mailer`, promote that module to a top-level leaf boundary instead of exporting it from `Flick`.

5. Update the table above.

## See a violation

Add a direct `Flick.Repo` call to a LiveView, for example in `mount/3` of `lib/flick_web/live/index_live.ex`:

```elixir
alias Flick.Repo

def mount(_params, _session, socket) do
  _ = Repo.aggregate(Flick.RankedVoting.Ballot, :count)
  # ...
end
```

Then run `mix compile --warnings-as-errors`. The build fails with this warning:

```text
warning: forbidden reference to Flick.Repo
  (references from FlickWeb to Flick.Repo are not allowed)
  lib/flick_web/live/index_live.ex:14
```

A reference to a context's private module fails the same way, with a different reason:

```text
warning: forbidden reference to Flick.RankedVoting.EmbedParams
  (module Flick.RankedVoting.EmbedParams is not exported by its owner boundary Flick.RankedVoting)
```

The fix is to go through the context's public API, for example by adding a function to `Flick.RankedVoting`. Revert the demo edit afterward.

## Useful commands

```console
# Print every boundary with its exports and deps.
mix boundary.spec

# Show external (library) dependencies grouped by boundary.
mix boundary.find_external_deps

# Generate Graphviz .dot files of the boundaries.
mix boundary.visualize
```

## Troubleshooting

**`unknown module X is listed as an export`**: an incremental compile can report an exported module as unknown when only the boundary file recompiled. This is a [known Boundary issue](https://github.com/sasa1977/boundary/issues/72). A clean compile resolves it:

```console
mix clean && mix compile
```

In CI, bump the `cache-key` default in `.github/actions/elixir-setup/action.yml` to discard the cached `_build`.
