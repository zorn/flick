defmodule FlickWeb.Vote.VoteCaptureLive do
  @moduledoc """
  A live view that presents a ranked voting form for a published
  `Flick.RankedVoting.Ballot` entity.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Vote
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"url_slug" => url_slug} = params
    ballot = RankedVoting.get_ballot_by_url_slug!(url_slug)

    socket
    |> verify_ballot_is_published(ballot)
    |> assign(:page_title, "Vote: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> assign_form()
    |> ok()
  end

  @spec assign_form(Socket.t()) :: Socket.t()
  defp assign_form(socket) do
    %{ballot: ballot} = socket.assigns

    # We'll generate ranked answer values for each possible answer in the ballot, up to 5.
    ranked_answer_count = RankedVoting.allowed_answer_count_for_ballot(ballot)
    ranked_answers = Enum.map(1..ranked_answer_count, fn _ -> %{value: nil} end)

    vote_params = %{ballot_id: ballot.id, ranked_answers: ranked_answers}
    changeset = RankedVoting.change_vote(%Vote{}, vote_params)
    assign(socket, form: to_form(changeset))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"vote" => vote_params}, socket) do
    changeset = RankedVoting.change_vote(%Vote{}, vote_params, action: :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"vote" => vote_params}, socket) do
    %{ballot: ballot} = socket.assigns

    case RankedVoting.create_vote(ballot, vote_params) do
      {:ok, _vote} ->
        socket
        |> put_flash(:info, "Vote recorded.")
        |> redirect(to: ~p"/")
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(form: to_form(changeset))
        |> noreply()
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div id="question-title"><%= @ballot.question_title %></div>

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
    [nil] ++ Flick.RankedVoting.Ballot.possible_answers_as_list(ballot.possible_answers)
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
