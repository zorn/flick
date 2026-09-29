# Decision: Module Boundaries

Flick adopts the [`boundary`](https://github.com/sasa1977/boundary) library so
that a call reaching past a context's public API fails the build. Today there is
one context, `Flick.RankedVoting`, but optional accounts and ballot-close
notifications are likely next. Much of the new code will be AI-generated, and
Boundary turns "go through the context" from a review convention into a
compile-time rule before those contexts arrive.

The layout matches LocalCents. The root `Flick` boundary exports nothing, each
context is its own boundary, and `Flick.Application` uses `top_level?: true`
rather than being renamed to `FlickApp`, as Boundary's docs prefer. Test
helpers declare their own dependencies instead of sharing one unchecked
boundary.

`Flick.RankedVoting` exports its schemas (`Ballot`, `Vote`, `PossibleAnswer`,
`RankedAnswer`), because LiveViews build and pattern-match them. `EmbedParams`
stays private. The web layer may use `Flick.Markdown` and
`Flick.DateTimeFormatter`, but never `Flick.Repo` or `Flick.Mailer`.

`Vote` drops `use Gettext, backend: FlickWeb.Gettext`, the only dependency from
the domain on the web layer. Its validation messages become plain strings with
`%{count}` bindings. `CoreComponents.translate_error` already translates them at
render time, and the app ships only `en`.

Decided in [Consider adding Boundry.](https://github.com/zorn/flick/issues/72).
