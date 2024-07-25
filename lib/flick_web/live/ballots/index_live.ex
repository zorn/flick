defmodule FlickWeb.Ballots.IndexLive do
  @moduledoc """
  A live view that presents the known list of `Flick.RankedVoting.Ballot` entities.
  """

  # TODO: In the future we probably won't just list all ballots, but for early
  # development this is helpful.

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Ballot Index")
    |> assign(:ballots, Flick.RankedVoting.list_ballots())
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <p>
        <.link navigate={~p"/ballots/new"} class="underline">Create a new ballot.</.link>
      </p>
      <p>A list of known ballots.</p>
    </div>

    <.table id="ballots" rows={@ballots} row_id={&"ballot-row-#{&1.id}"}>
      <:col :let={ballot} label="Title">
        <%= ballot.question_title %>
      </:col>
      <:col :let={ballot} label="Published">
        <%= if ballot.published_at do %>
          <%= ballot.published_at %>
        <% else %>
          Not Published
        <% end %>
      </:col>
      <:col :let={ballot}>
        <.link :if={ballot.published_at} navigate={~p"/vote/#{ballot.id}"}>Voting Page</.link>
      </:col>
      <:col :let={ballot}>
        <.link navigate={~p"/ballots/#{ballot.id}"}>View Details</.link>
      </:col>
    </.table>
    """
  end
end
