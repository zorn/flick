defmodule Flick.Repo do
  use Boundary, top_level?: true, deps: []

  use Ecto.Repo,
    otp_app: :flick,
    adapter: Ecto.Adapters.Postgres
end
