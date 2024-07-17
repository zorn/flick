defmodule FlickWeb.Ballots.EditorLive do
  @moduledoc """
  A live view that presents a form for the creation or editing of a
  `Flick.Ballots.Ballot`.
  """

  use FlickWeb, :live_view

  alias Flick.Ballots
  alias Flick.Ballots.Ballot

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    ballot = ballot(params, socket)
    form = to_form(Ballots.change_ballot(ballot, %{}))

    socket
    |> assign(:form, form)
    |> assign(:ballot, ballot)
    |> assign_page_title()
    |> ok()
  end

  defp assign_page_title(%{assigns: %{live_action: :edit, ballot: ballot}} = socket) do
    assign(socket, page_title: "Edit Ballot: #{ballot.question_title}")
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Create a Ballot")
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

    case Ballots.update_ballot(ballot, ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballots/#{ballot}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp do_save(params, socket) do
    %{"ballot" => ballot_params} = params

    case Ballots.create_ballot(ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballots/#{ballot}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <h2>Create Ballot</h2>
      <p>
        <.back navigate={~p"/ballots"}>Back to ballots</.back>
      </p>
    </div>

    <.simple_form for={@form} phx-change="validate" phx-submit="save">
      <.input field={@form[:question_title]} label="Question Title" />
      <.input field={@form[:possible_answers]} label="Possible Answers (comma separated)" />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end
end
