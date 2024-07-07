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
  alias Flick.Votes
  alias Flick.Votes.Vote

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"ballot_id" => ballot_id} = params

    ballot = Ballots.get_ballot!(ballot_id)

    dbg(ballot)

    # I think what we want this to be, is that is
    # build initial vote params
    attrs =
      Enum.map(ballot.questions, fn question ->
        %{
          "question_id" => question.id,
          "ranked_answers" => [%{value: nil}]
        }
      end)

    changeset =
      Votes.change_vote(%Vote{}, %{
        "ballot_id" => ballot.id,
        "question_responses" => attrs
      })

    dbg(changeset)

    form = to_form(changeset)

    socket
    |> verify_ballot_is_published(ballot)
    |> assign(:page_title, "Vote: #{ballot.title}")
    |> assign(:ballot, ballot)
    |> assign(:form, form)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"vote" => vote_params}, socket) do
    dbg("validate")
    dbg(vote_params)

    changeset = Votes.change_vote(%Vote{}, vote_params)
    dbg(changeset)

    form = to_form(changeset)
    socket = assign(socket, form: form)

    {:noreply, socket}
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
      <div><%= @ballot.title %></div>

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input type="hidden" field={@form[:ballot_id]} value={@ballot.id} />
        <.inputs_for :let={question_response_form} field={@form[:question_responses]}>
          <h3><%= question_label(@ballot, question_response_form[:question_id]) %></h3>
          <.input type="hidden" field={question_response_form[:question_id]} />

          <%!-- present selects for first ranked answer selection --%>
          <.inputs_for :let={ranked_answers_form} field={question_response_form[:ranked_answers]}>
            <.input
              field={ranked_answers_form[:value]}
              type="select"
              options={[nil] ++ possible_values(@ballot, question_response_form[:question_id])}
            />
          </.inputs_for>
        </.inputs_for>
        <:actions>
          <.button>Record Vote</.button>
        </:actions>
      </.simple_form>

      <%!-- <div class="grid grid-cols-5">
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
      </div> --%>
    </div>
    """
  end

  defp question_label(ballot, %Phoenix.HTML.FormField{value: question_id}) do
    question = Enum.find(ballot.questions, &(&1.id == question_id))

    question.title
  end

  defp possible_values(ballot, %Phoenix.HTML.FormField{value: question_id}) do
    question = Enum.find(ballot.questions, &(&1.id == question_id))
    possible_values(ballot, question)
  end

  defp possible_values(_ballot, question) do
    # Maybe this belongs in the core ?

    possible_answers = Flick.Ballots.Ballot.possible_answers_as_list(question.possible_answers)

    possible_answers
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
