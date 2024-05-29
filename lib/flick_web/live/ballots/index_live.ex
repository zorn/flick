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
      <.table id="ballots" rows={@ballots} row_id={&"ballot-row-#{&1.id}"}>
        <:col :let={ballot} label="title">
          <%= ballot.title %>
        </:col>
        <:col :let={ballot} label="published at">
          <%= ballot.published_at || "Not Published" %>
        </:col>
        <:col :let={ballot} label="details">
          <.link navigate={~p"/ballots/#{ballot.id}"}>View Details</.link>
        </:col>
      </.table>
    </div>
    """
  end
end
