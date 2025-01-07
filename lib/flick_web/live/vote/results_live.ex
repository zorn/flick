defmodule FlickWeb.Vote.ResultsLive do
  @moduledoc """
  A live view that presents the results of a closed `Flick.RankedVoting.Ballot` entity.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"url_slug" => url_slug} = params
    ballot = RankedVoting.get_ballot_by_url_slug!(url_slug)

    if ballot.closed_at do
      socket
      |> assign(:page_title, "Results: #{ballot.question_title}")
      |> assign(:ballot, ballot)
      |> assign(:ballot_results_report, RankedVoting.get_ballot_results_report(ballot.id))
      |> assign(:vote_count, RankedVoting.count_votes_for_ballot_id(ballot.id))
      |> ok()
    else
      socket
      |> put_flash(:error, "This ballot is not closed and results are unavailable.")
      |> redirect(to: ~p"/")
      |> ok()
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <h1>Ballot Results</h1>

      <p>For the ballot asking <strong>{@ballot.question_title}</strong> the results in!</p>

      <p>With a total of {@vote_count} votes cast, the outcome of the ranked vote is:</p>

      <ol>
        <%= for %{points: points, value: answer} <- @ballot_results_report do %>
          <li>{answer}: {points} points</li>
        <% end %>
      </ol>
    </div>
    """
  end
end
