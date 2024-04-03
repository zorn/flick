defmodule Flick.Repo do
  use Ecto.Repo,
    otp_app: :flick,
    adapter: Ecto.Adapters.Postgres
end
