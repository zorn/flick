defmodule FlickWeb.Vote.VoteCaptureLive do
  @moduledoc """
  A live view that presents a ranked voting form for a published
  `Flick.Ballots.Ballot` entity.
  """

  use FlickWeb, :live_view

  alias Flick.Ballots

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"ballot_id" => ballot_id} = params

    ballot = Ballots.get_ballot!(ballot_id)

    socket
    |> verify_ballot_is_published(ballot)
    |> assign(:page_title, "Vote: #{ballot.title}")
    |> assign(:ballot, ballot)
    |> ok()
  end

  defp verify_ballot_is_published(socket, ballot) do
    if ballot.published_at do
      socket
    else
      # TODO: We can make this a better user experience in the future.
      throw("can not vote on an unpublished ballot")
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div>The Question</div>

      <div class="grid grid-cols-5">
        <div>
          <!-- empty -->
        </div>
        <div>1st Choice</div>
        <div>2nd Choice</div>
        <div>3rd Choice</div>
        <div>4th Choice</div>

        <div>Answer Option A</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>

        <div>Answer Option B</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>

        <div>Answer Option C</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>

        <div>Answer Option D</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>

        <div>Answer Option E</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>

        <div>Answer Option F</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
        <div>input</div>
      </div>
    </div>
    """
  end
end
