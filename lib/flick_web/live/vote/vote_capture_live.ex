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

    cond do
      ballot.closed_at ->
        socket
        |> redirect(to: ~p"/ballot/#{ballot.url_slug}/results")
        |> ok()

      ballot.published_at ->
        socket
        |> assign(:page_title, "Vote: #{ballot.question_title}")
        |> assign(:ballot, ballot)
        |> assign_form()
        |> ok()

      true ->
        socket
        |> put_flash(:error, "This ballot is unpublished and can not accept votes.")
        |> redirect(to: ~p"/")
        |> ok()
    end
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
      <div>
        <p>Use the form below to submit your vote.</p>
      </div>

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <%!-- I wonder if we should drop this hidden and just inject the id manually? --%>
        <.input type="hidden" field={@form[:ballot_id]} value={@ballot.id} />
        <.input field={@form[:full_name]} label="Name (Optional)" />

        <div id="question-title" class="prose">
          <h2>{@ballot.question_title}</h2>

          <div>
            {@ballot.description && Flick.Markdown.render_to_html(@ballot.description)}
          </div>
        </div>

        <.inputs_for :let={ranked_answer_form} field={@form[:ranked_answers]}>
          <.input
            field={ranked_answer_form[:value]}
            type="select"
            options={options(@ballot)}
            label={answer_label(ranked_answer_form.id)}
          />
        </.inputs_for>
        <:actions>
          <.button>Submit Vote</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp answer_label("vote_ranked_answers_" <> number = _form_id) do
    case number do
      "0" -> "First Preference"
      "1" -> "Second Preference (Optional)"
      "2" -> "Third Preference (Optional)"
      "3" -> "Fourth Preference (Optional)"
      "4" -> "Fifth Preference (Optional)"
    end
  end

  defp options(ballot) do
    [nil] ++ Flick.RankedVoting.Ballot.possible_answers_as_list(ballot.possible_answers)
  end
end
