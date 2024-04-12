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
  alias Flick.Ballots.Question

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Going to assume creation for a bit
    form = to_form(Ballots.change_ballot(%Ballot{}, %{}))

    socket
    # TODO: Update page title to be more editor centric when I add editing.
    |> assign(:page_title, "Create a Ballot")
    |> assign(:form, form)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    %{"title" => title} = params["ballot"]

    form = to_form(Ballots.change_ballot(%Ballot{}, %{"title" => title}))

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    %{"title" => title} = params["ballot"]

    questions = [
      %Question{title: "What is your favorite color?"},
      %Question{title: "What is your favorite food?"}
    ]

    case Ballots.create_ballot(title, questions) do
      {:ok, _ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballots")}

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
        <.input field={@form[:title]} label="Title" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
