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

  @impl PromEx
  def dashboard_assigns do
    [datasource_id: "prometheus", default_selected_interval: "30s"]
  end

  @impl PromEx
  def dashboards, do: []
end
