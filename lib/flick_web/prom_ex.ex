defmodule FlickWeb.PromEx do
  @moduledoc """
  Collects Prometheus metrics for Flick and serves them at `/metrics`.

  See `FlickWeb.PromEx.RankedVotingPlugin` for Flick's own metrics.
  """

  use PromEx, otp_app: :flick

  alias PromEx.Plugins

  @impl PromEx
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: FlickWeb.Router, endpoint: FlickWeb.Endpoint},
      Plugins.Ecto,
      Plugins.PhoenixLiveView,
      FlickWeb.PromEx.RankedVotingPlugin
    ]
  end

  # `mix prom_ex.dashboard.export` reads this. PromEx has no default for
  # `datasource_id`, and Grafana provisions the data source with this uid.
  @impl PromEx
  def dashboard_assigns, do: [datasource_id: "prometheus"]
end
