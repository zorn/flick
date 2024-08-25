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
      <p id="welcome-copy">
        Flick is an application that allows you to create ballots that capture ranked votes.
      </p>

      <p><.link navigate={~p"/ballot/new"}>Create a ballot</.link> and try it out.</p>
    </div>
    """
  end
end
