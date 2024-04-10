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
    |> assign(:ballots, Flick.Ballots.list_ballots())
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p>
        <.link navigate={~p"/ballots/new"} class="underline">Create a new ballot.</.link>
      </p>
      <p>A list of known ballots.</p>
      <.table id="ballots" rows={@ballots}>
        <:col :let={ballot} label="id"><%= ballot.id %></:col>
        <:col :let={ballot} label="title">
          <.link navigate={~p"/ballots/#{ballot.id}"}><%= ballot.title %></.link>
        </:col>
      </.table>
    </div>
    """
  end
end
