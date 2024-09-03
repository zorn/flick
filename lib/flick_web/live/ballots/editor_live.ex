defmodule FlickWeb.Ballots.EditorLive do
  @moduledoc """
  A live view that presents a form for the creation or editing of a
  `Flick.RankedVoting.Ballot`.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    ballot = ballot(params, socket)
    form = to_form(RankedVoting.change_ballot(ballot, %{}))

    socket
    |> assign(:form, form)
    |> assign(:ballot, ballot)
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

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    %{"ballot" => ballot_params} = params
    %{ballot: ballot} = socket.assigns
    form = to_form(RankedVoting.change_ballot(ballot, ballot_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    do_save(params, socket)
  end

  defp do_save(params, %{assigns: %{live_action: :edit}} = socket) do
    %{"ballot" => ballot_params} = params
    %{ballot: ballot} = socket.assigns

    case RankedVoting.update_ballot(ballot, ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp do_save(params, socket) do
    %{"ballot" => ballot_params} = params

    case RankedVoting.create_ballot(ballot_params) do
      {:ok, ballot} ->
        {:noreply, redirect(socket, to: ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose">
      <h2><%= page_title(@live_action) %></h2>
    </div>

    <.simple_form for={@form} phx-change="validate" phx-submit="save">
      <.input field={@form[:question_title]} label="Question Title" placeholder="What is for dinner?" />

      <.input field={@form[:description]} type="textarea" label="Description (Markdown)" placeholder="Some context to help people know about the possible answers. " />

      <.input
        field={@form[:possible_answers]}
        label="Possible Answers (comma separated)"
        placeholder="Chicken, Pasta, Pancakes"
      />
      <.input
        field={@form[:url_slug]}
        label="URL Slug (as seen in the URL you'll give to voters)"
        placeholder="what-is-for-dinner"
      />

      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  defp page_title(:edit), do: "Edit Ballot"
  defp page_title(_), do: "Create a Ballot"
end
