defmodule FlickWeb.Ballots.EditorLive do
  @moduledoc """
  A live view that presents a form for the creation or editing of a
  `Flick.Ballots.Ballot`.
  """

  # TODO: Normalize a better way to say "Ballot" and have it link without
  # showing the full module path. Maybe come up with a typing shortcut to help
  # me?

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      Hello world.
    </div>
    """
  end
end
