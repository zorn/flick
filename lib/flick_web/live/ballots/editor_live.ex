defmodule FlickWeb.Ballots.EditorLive do
  @moduledoc """
  A live view that presents a form for the creation or editing of a
  `Flick.Ballots.Ballot`.
  """

  # TODO: Normalize a better way to say "Ballot" and have it link without
  # showing the full module path. Maybe come up with a typing shortcut to help
  # me?

  use FlickWeb, :live_view

  alias Flick.Ballots
  alias Flick.Ballots.Ballot

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    # do I need to save this to the assigns?
    ballot = ballot(params, socket)
    form = to_form(Ballots.change_ballot(ballot, %{}))

    socket
    # TODO: Update page title to be more editor centric when I add editing.
    |> assign(:page_title, "Create a Ballot")
    |> assign(:form, form)
    |> assign(:ballot, ballot)
    |> ok()
  end

  defp ballot(params, %{assigns: %{live_action: :edit}} = _socket) do
    %{"ballot_id" => ballot_id} = params
    Ballots.get_ballot!(ballot_id)
  end

  defp ballot(_params, _socket) do
    %Ballot{}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    %{"ballot" => ballot_params} = params
    %{ballot: ballot} = socket.assigns
    form = to_form(Ballots.change_ballot(ballot, ballot_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    do_save(params, socket)
  end

  defp do_save(params, %{assigns: %{live_action: :edit}} = socket) do
    %{"ballot" => ballot_params} = params
    %{ballot: ballot} = socket.assigns

    dbg(ballot_params)

    case Ballots.update_ballot(ballot, ballot_params) do
      {:ok, _ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballots")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp do_save(params, socket) do
    %{"title" => title} = params["ballot"]
    %{ballot: ballot} = socket.assigns

    case Ballots.update_ballot(ballot, %{"title" => title}) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballots/#{ballot}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p>
        <.back navigate={~p"/ballots"}>Back to ballots</.back>
      </p>
      <p id="ballot-form">Some form experience.</p>

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} label="Ballot Title" />

        <.inputs_for :let={question_form} field={@form[:questions]}>
          <input type="hidden" name="ballot[questions_sort][]" value={question_form.index} />

          <.input field={question_form[:title]} label="Question Title" />

          <label>
            <input
              type="checkbox"
              name="ballot[questions_drop][]"
              value={question_form.index}
              class="hidden"
            /> delete event
          </label>
        </.inputs_for>

        <input type="hidden" name="ballot[questions_drop][]" />

        <label class="block cursor-pointer">
          <input type="checkbox" name="ballot[questions_sort][]" class="hidden" /> add event
        </label>

        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
