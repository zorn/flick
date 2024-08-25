defmodule Flick.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.

  References:

  - https://staknine.com/deploy-elixir-phoenix-render/
  - https://fullstackphoenix.com/tutorials/step-by-step-guide-to-deploy-phoenix-1-6-with-liveview-and-tailwind-on-render
  - https://docs.render.com/deploy-phoenix
  """
  @app :flick

  def migrate do
    ensure_started()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    ensure_started()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp ensure_started do
    # Since Render uses SSL to connect to the database, you need to start SSL before running your migrations.
    # https://elixirforum.com/t/ssl-connection-cannot-be-established-using-elixir-releases/25444/5
    Application.ensure_all_started(:ssl)
  end
end
