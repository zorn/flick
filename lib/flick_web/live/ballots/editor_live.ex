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

    changeset =
      ballot
      |> RankedVoting.change_ballot(ballot_params)
      |> Map.put(:action, :validate)
      |> hide_blank_row_errors()

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ballot" => ballot_params}, socket) do
    do_save(drop_blank_possible_answers(ballot_params), socket)
  end

  # Saving drops blank rows, so their "can't be blank" errors would only
  # distract the owner while typing.
  defp hide_blank_row_errors(%{changes: %{possible_answers: rows}} = changeset) do
    rows = Enum.map(rows, &Map.update!(&1, :errors, fn errors -> reject_required(errors) end))
    put_in(changeset.changes.possible_answers, rows)
  end

  defp hide_blank_row_errors(changeset), do: changeset

  defp reject_required(errors) do
    Enum.reject(errors, fn {_field, {_message, opts}} -> opts[:validation] == :required end)
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
          <div id="possible-answer-rows" phx-hook="SortableInputsFor" class="space-y-3">
            <.inputs_for :let={answer_form} field={@form[:possible_answers]}>
              <div data-row class="flex items-end gap-2">
                <input type="hidden" name="ballot[possible_answers_sort][]" value={answer_form.index} />
                <span
                  data-handle
                  aria-hidden="true"
                  title="Drag to reorder"
                  class="cursor-grab touch-none rounded p-1 pb-2.5 text-zinc-400 transition hover:text-zinc-700 active:cursor-grabbing"
                >
                  <.icon name="hero-bars-3-mini" class="h-5 w-5" />
                </span>
                <div class="flex-1">
                  <.input
                    field={answer_form[:value]}
                    placeholder={answer_placeholder(answer_form.index)}
                    aria-label={"Answer #{answer_form.index + 1}"}
                  />
                </div>
                <div class="flex items-center text-zinc-400">
                  <.move_button
                    index={answer_form.index}
                    direction="up"
                    disabled={answer_form.index == 0}
                  />
                  <.move_button
                    index={answer_form.index}
                    direction="down"
                    disabled={answer_form.index == @answer_count - 1}
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
          </div>

          <input type="hidden" name="ballot[possible_answers_drop][]" />

          <button
            type="button"
            id="add-possible-answer"
            name="ballot[possible_answers_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
            disabled={@answer_count >= Ballot.max_possible_answers()}
            class="inline-flex items-center gap-1 rounded-lg border border-dashed border-zinc-300 px-3 py-1.5 text-sm font-semibold text-teal-700 transition hover:border-teal-500 hover:bg-teal-50 disabled:border-zinc-200 disabled:text-zinc-300 disabled:hover:bg-transparent"
          >
            <.icon name="hero-plus-mini" class="h-4 w-4" /> Add another answer
          </button>

          <p
            :if={@answer_count >= Ballot.max_possible_answers()}
            id="possible-answers-max-note"
            class="text-xs text-zinc-500"
          >
            A ballot can have at most {Ballot.max_possible_answers()} answers.
          </p>

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

  attr :index, :integer, required: true
  attr :direction, :string, required: true, values: ~w(up down)
  attr :disabled, :boolean, required: true

  defp move_button(assigns) do
    ~H"""
    <button
      type="button"
      id={"move-possible-answer-#{@direction}-#{@index}"}
      data-move={@direction}
      disabled={@disabled}
      aria-label={"Move answer #{@index + 1} #{@direction}"}
      class="rounded p-1 transition hover:bg-zinc-100 hover:text-zinc-700 disabled:opacity-30 disabled:hover:bg-transparent"
    >
      <.icon name={move_icon(@direction)} class="h-5 w-5" />
    </button>
    """
  end

  # Tailwind builds only the icon classes it finds spelled out in the source.
  defp move_icon("up"), do: "hero-chevron-up-mini"
  defp move_icon("down"), do: "hero-chevron-down-mini"

  # The second title's commas show that an answer may contain them.
  defp answer_placeholder(0), do: "Project Hail Mary by Andy Weir"
  defp answer_placeholder(1), do: "Tomorrow, and Tomorrow, and Tomorrow by Gabrielle Zevin"
  defp answer_placeholder(_index), do: "Another book"

  defp page_title(:edit), do: "Edit Ballot"
  defp page_title(_), do: "Create a Ballot"
end
