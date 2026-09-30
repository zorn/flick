defmodule Flick do
  @moduledoc """
  The root boundary. It holds shared infrastructure, such as `Flick.Mailer`
  and `Flick.Release`, that no other boundary may call.

  Each domain context, such as `Flick.RankedVoting`, is a top-level boundary of
  its own. See `docs/module-boundaries.md`.
  """

  use Boundary, deps: [], exports: []
end
