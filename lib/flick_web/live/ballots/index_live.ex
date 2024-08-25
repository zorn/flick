defmodule FlickWeb.Ballots.IndexLive do
  @moduledoc """
  A live view that presents the known list of `Flick.RankedVoting.Ballot` entities.

  This view will be only accessible to authenticated users, per:
  https://github.com/zorn/flick/issues/29
  """

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Admin: Ballots")
    |> assign(:ballots, Flick.RankedVoting.list_ballots())
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <p>Admin: Ballots</p>
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
        <.link :if={ballot.published_at} href={~p"/ballot/#{ballot.url_slug}"}>Voting Page</.link>
      </:col>
      <:col :let={ballot}>
        <.link href={~p"/ballot/#{ballot.url_slug}/#{ballot.secret}"}>Ballot Details</.link>
      </:col>
    </.table>
    """
  end
end
