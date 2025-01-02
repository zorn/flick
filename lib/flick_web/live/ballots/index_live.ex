defmodule FlickWeb.Ballots.IndexLive do
  @moduledoc """
  A live view that presents the known list of `Flick.RankedVoting.Ballot` entities.

  This view will be only accessible to authenticated users, per:
  https://github.com/zorn/flick/issues/29
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting.Ballot

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
    <div class="prose mb-4">
      <h2>Administration</h2>

      <p>
        The following page is a list of all ballots in the system, allowing an authenticated admin to quickly see and link to each page.
      </p>

      <p>Only authenticated admins can see this page.</p>

      <h2>Ballots</h2>
    </div>

    <.table id="ballots" rows={@ballots} row_id={&"ballot-row-#{&1.id}"}>
      <:col :let={ballot} label="Title">
        <div class="text-lg mb-4">
          {ballot.question_title}
        </div>

        <div class="font-normal">
          <.link href={~p"/ballot/#{ballot.url_slug}"} class="underline">
            Voting Page
          </.link>
          &bull;
          <.link href={~p"/ballot/#{ballot.url_slug}/#{ballot.secret}"} class="underline">
            Ballot Admin Page
          </.link>
        </div>
      </:col>
      <:col :let={ballot} label="Status">
        <div title={"#{status_date_label(ballot)}"}>{status_label(ballot)}</div>
      </:col>
    </.table>
    """
  end

  defp status_label(%Ballot{} = ballot) do
    case Flick.RankedVoting.ballot_status(ballot) do
      :closed -> "Closed"
      :published -> "Published"
      :draft -> "Draft"
    end
  end

  defp status_date_label(%Ballot{} = ballot) do
    case Flick.RankedVoting.ballot_status(ballot) do
      :closed -> "Closed on #{ballot.closed_at}"
      :published -> "Published on #{ballot.published_at}"
      :draft -> "Created on #{ballot.inserted_at}"
    end
  end
end
