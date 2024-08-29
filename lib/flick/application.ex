defmodule Flick.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Appsignal.Phoenix.LiveView.attach()

    children = [
      FlickWeb.Telemetry,
      Flick.Repo,
      {DNSCluster, query: Application.get_env(:flick, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Flick.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Flick.Finch},
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
  @impl true
  def config_change(changed, _new, removed) do
    FlickWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
