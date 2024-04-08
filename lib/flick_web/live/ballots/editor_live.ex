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
    socket
    # TODO: Update page title to be more editor centric when I add editing.
    |> assign(:page_title, "Create a Ballot")
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p>
        <.back navigate={~p"/ballots"}>Back to ballots</.back>
      </p>
      <p>Hello world.</p>
    </div>
    """
  end
end
