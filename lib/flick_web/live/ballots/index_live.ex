defmodule FlickWeb.Ballots.IndexLive do
  @moduledoc """
  A live view that presents the known list of `Flick.Ballots.Ballot` entities.
  """

  # TODO: In the future we probably won't just list all ballots, but for early
  # development this is helpful.

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Ballot Index")
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p>
        <.link patch={~p"/ballots/new"} class="underline">Create a new ballot.</.link>
      </p>
      <p>A list of known ballots.</p>
    </div>
    """
  end
end
