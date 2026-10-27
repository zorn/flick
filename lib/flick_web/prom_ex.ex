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
      {Plugins.Application, git_sha_mfa: {__MODULE__, :git_sha, []}},
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

  @doc """
  Returns the running commit for `application_git_sha_info`.

  Render sets `RENDER_GIT_COMMIT` on every deploy. Outside Render, this
  returns `"unknown"`.
  """
  @spec git_sha() :: String.t()
  def git_sha, do: System.get_env("RENDER_GIT_COMMIT", "unknown")
end
