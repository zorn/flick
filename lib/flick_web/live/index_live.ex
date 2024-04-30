defmodule FlickWeb.IndexLive do
  @moduledoc """
  A live view for the root page of the app.

  Currently this view just redirects to the ballots index.
  """

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/ballots")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      An index page that never renders. Who am I?
    </div>
    """
  end
end
