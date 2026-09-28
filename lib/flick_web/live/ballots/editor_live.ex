defmodule FlickWeb.Ballots.EditorLive do
  @moduledoc """
  A live view that presents a form for the creation or editing of a
  `Flick.RankedVoting.Ballot`.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.PossibleAnswer

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    ballot = ballot(params, socket)

    socket
    |> assign(:ballot, ballot)
    |> assign_form(RankedVoting.change_ballot(ballot, initial_params(ballot)))
    |> assign_page_title()
    |> ok()
  end

  defp assign_page_title(%{assigns: %{live_action: :edit, ballot: ballot}} = socket) do
    assign(socket, page_title: "Edit Ballot: #{ballot.question_title}")
  end

  defp assign_page_title(%{assigns: %{live_action: :edit}} = socket) do
    assign(socket, page_title: "Edit Ballot")
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Create a Ballot")
  end

  defp ballot(params, %{assigns: %{live_action: :edit}} = _socket) do
    %{"url_slug" => url_slug, "secret" => secret} = params
    RankedVoting.get_ballot_by_url_slug_and_secret!(url_slug, secret)
  end

  defp ballot(_params, _socket) do
    %Ballot{}
  end

  # Start with the minimum number of rows.
  defp initial_params(%Ballot{id: nil}) do
    %{"possible_answers_sort" => List.duplicate("new", Ballot.min_possible_answers())}
  end

  defp initial_params(_ballot), do: %{}

  defp assign_form(socket, changeset) do
    socket
    |> assign(:form, to_form(changeset))
    |> assign(:answer_count, length(Ecto.Changeset.get_field(changeset, :possible_answers)))
  end

  # Saving drops blank rows, so a failed save can come back with fewer rows
  # than the minimum. Add empty ones back so the owner has somewhere to type.
  # On edit, the dropped rows remain as `:replace` changesets; they are left
  # out here because they are neither shown nor accepted by `put_embed/3`.
  defp pad_possible_answers(changeset) do
    answers =
      changeset
      |> Ecto.Changeset.get_embed(:possible_answers)
      |> Enum.reject(&(&1.action == :replace))

    missing = Ballot.min_possible_answers() - length(answers)

    if missing > 0 do
      blanks = List.duplicate(%PossibleAnswer{}, missing)
      Ecto.Changeset.put_embed(changeset, :possible_answers, answers ++ blanks)
    else
      changeset
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    %{"ballot" => ballot_params} = params
    %{ballot: ballot} = socket.assigns
    {:noreply, assign_form(socket, RankedVoting.change_ballot(ballot, ballot_params))}
  end

  def handle_event("save", %{"ballot" => ballot_params}, socket) do
    do_save(drop_blank_possible_answers(ballot_params), socket)
  end

  # The form offers empty rows to type into, so saving drops the ones left
  # blank. Validation keeps them, or they would vanish while the owner types.
  defp drop_blank_possible_answers(%{"possible_answers" => answers} = ballot_params) do
    blank_indexes =
      for {index, %{"value" => value}} <- answers, String.trim(value) == "", do: index

    Map.update(ballot_params, "possible_answers_drop", blank_indexes, &(&1 ++ blank_indexes))
  end

  defp drop_blank_possible_answers(ballot_params), do: ballot_params

  defp do_save(ballot_params, %{assigns: %{live_action: :edit}} = socket) do
    %{ballot: ballot} = socket.assigns

    case RankedVoting.update_ballot(ballot, ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, pad_possible_answers(changeset))}
    end
  end

  defp do_save(ballot_params, socket) do
    case RankedVoting.create_ballot(ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, pad_possible_answers(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="prose">
        <h2>{page_title(@live_action)}</h2>
      </div>

      <.simple_form for={@form} id="ballot-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:question_title]}
          label="Question Title"
          placeholder="What should the book club read next?"
        />

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description (Markdown)"
          placeholder="Some context to help voters choose, like page counts or where to find each book."
        />

        <fieldset id="possible-answers" class="space-y-3">
          <legend class="text-sm font-semibold leading-6 text-zinc-800">Possible Answers</legend>
          <p class="text-xs text-zinc-500">Voters see answers in this order.</p>
          <.inputs_for :let={answer_form} field={@form[:possible_answers]}>
            <div class="flex items-end gap-2">
              <input type="hidden" name="ballot[possible_answers_sort][]" value={answer_form.index} />
              <div class="flex-1">
                <.input
                  field={answer_form[:value]}
                  placeholder={answer_placeholder(answer_form.index)}
                  aria-label={"Answer #{answer_form.index + 1}"}
                />
              </div>
              <button
                type="button"
                id={"remove-possible-answer-#{answer_form.index}"}
                name="ballot[possible_answers_drop][]"
                value={answer_form.index}
                phx-click={JS.dispatch("change")}
                disabled={@answer_count <= Ballot.min_possible_answers()}
                class="rounded px-2 py-1 text-sm font-semibold text-rose-600 transition hover:bg-rose-50 disabled:text-zinc-300 disabled:hover:bg-transparent"
              >
                Remove
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="ballot[possible_answers_drop][]" />

          <button
            type="button"
            id="add-possible-answer"
            name="ballot[possible_answers_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
            class="inline-flex items-center gap-1 rounded-lg border border-dashed border-zinc-300 px-3 py-1.5 text-sm font-semibold text-teal-700 transition hover:border-teal-500 hover:bg-teal-50"
          >
            <.icon name="hero-plus-mini" class="h-4 w-4" /> Add another answer
          </button>

          <div :if={@form[:possible_answers].errors != []} id="possible-answers-errors">
            <.error :for={error <- @form[:possible_answers].errors}>
              {translate_error(error)}
            </.error>
          </div>
        </fieldset>

        <.input
          field={@form[:url_slug]}
          label="URL Slug (as seen in the URL you'll give to voters)"
          placeholder="book-club-next-read"
        />

        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  # The second title's commas show that an answer may contain them.
  defp answer_placeholder(0), do: "Project Hail Mary by Andy Weir"
  defp answer_placeholder(1), do: "Tomorrow, and Tomorrow, and Tomorrow by Gabrielle Zevin"
  defp answer_placeholder(_index), do: "Another book"

  defp page_title(:edit), do: "Edit Ballot"
  defp page_title(_), do: "Create a Ballot"
end
