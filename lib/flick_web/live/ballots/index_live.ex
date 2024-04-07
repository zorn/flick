defmodule FlickWeb.Ballots.IndexLive do
  @moduledoc """
  A live view that presents the known list of `Flick.Ballots.Ballot` entities.
  """

  # TODO: In the future we probably won't just list all ballots, but for early
  # development this is helpful.

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      A list of known ballots.
    </div>
    """
  end
end
