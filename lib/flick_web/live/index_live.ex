defmodule FlickWeb.IndexLive do
  @moduledoc """
  A live view for the root page of the app.

  Currently this view just redirects to the ballots index.
  """

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <p>Flick is a simple Elixir / Phoenix LiveView app for running ranked vote ballots.</p>

      <ul>
        <li><.link navigate={~p"/ballots"}>View Ballots</.link></li>
        <li><.link navigate={~p"/ballots/new"}>Create a Ballots</.link></li>
      </ul>
    </div>
    """
  end
end
