defmodule FlickWeb.Vote.VoteCaptureLive do
  @moduledoc """
  A live view that presents a ranked voting form for a published
  `Flick.Ballots.Ballot` entity.



  This feels very complex. I could remove complexity by simplifying.

  - only allow a single question per ballot.

  For that question allow 5 ranked votes, no more no less -- this would let me generate a form changeset with static values and not have to do a lot of dynamic insertion as the form changed. They don't have to answer all ranked answers but could. I could also do validation saying they can't have the same answer twice.
  """

  use FlickWeb, :live_view

  alias Flick.Ballots
  alias Flick.Ballots.Ballot
  alias Flick.Votes
  alias Flick.Votes.Vote

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"ballot_id" => ballot_id} = params
    ballot = Ballots.get_ballot!(ballot_id)

    socket
    |> verify_ballot_is_published(ballot)
    |> assign(:page_title, "Vote: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> assign_form()
    |> ok()
  end

  defp assign_form(socket) do
    %{ballot: ballot} = socket.assigns

    # We'll generate a ranked answer value for each possible answer in the ballot, up to 5 answers.
    possible_answer_count = Ballot.possible_answers_as_list(ballot.possible_answers) |> length()
    ranked_answer_count = min(5, possible_answer_count)
    ranked_answers = Enum.map(1..ranked_answer_count, fn _ -> %{value: nil} end)

    vote_params = %{ballot_id: ballot.id, ranked_answers: ranked_answers}
    changeset = Votes.change_vote(%Vote{}, vote_params)
    assign(socket, form: to_form(changeset))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"vote" => vote_params}, socket) do
    changeset = Votes.change_vote(%Vote{}, vote_params, action: :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", params, socket) do
    dbg("save")
    dbg(params)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div><%= @ballot.question_title %></div>

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <%!-- I wonder if we should drop this hidden and just inject the id manually? --%>
        <.input type="hidden" field={@form[:ballot_id]} value={@ballot.id} />
        <.inputs_for :let={ranked_answer_form} field={@form[:ranked_answers]}>
          <.input
            field={ranked_answer_form[:value]}
            type="select"
            options={options(@ballot)}
            label={answer_label(ranked_answer_form.id)}
          />
        </.inputs_for>
        <:actions>
          <.button>Record Vote</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp answer_label("vote_ranked_answers_" <> number = _form_id) do
    case number do
      "0" -> "1st Choice"
      "1" -> "2nd Choice"
      "2" -> "3rd Choice"
      "3" -> "4th Choice"
      "4" -> "5th Choice"
    end
  end

  defp options(ballot) do
    [nil] ++ Flick.Ballots.Ballot.possible_answers_as_list(ballot.possible_answers)
  end

  defp verify_ballot_is_published(socket, ballot) do
    if ballot.published_at do
      socket
    else
      # TODO: We can make this a better user experience in the future.
      throw("can not vote on an unpublished ballot")
    end
  end
end
