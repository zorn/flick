# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Flick.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Boundary, top_level?: true, deps: [Flick.Repo, FlickWeb]

  use Application

  @impl Application
  def start(_type, _args) do
    # Flick is public, so a request's own trace header starts a linked trace
    # rather than continuing it.
    OpentelemetryBandit.setup(public_endpoint: true)
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:flick, :repo])

    children = [
      FlickWeb.PromEx,
      FlickWeb.Telemetry,
      Flick.Repo,
      Flick.Repo.VersionCheck,
      {DNSCluster, query: Application.get_env(:flick, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Flick.PubSub},
      # Start a worker by calling: Flick.Worker.start_link(arg)
      # {Flick.Worker, arg},
      # Start to serve requests, typically the last entry
      FlickWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Flick.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    FlickWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
