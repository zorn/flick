defmodule FlickWeb.Ballots.ViewerLive do
  @moduledoc """
  A live view that presents a the generic presentation of a `Flick.Ballots.Ballot`.
  """

  # TODO: This is probably the live view we'll use for voters. We'll need another live view for ballot owners.

  use FlickWeb, :live_view

  alias Flick.Ballots

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"ballot_id" => ballot_id} = params

    ballot = Ballots.get_ballot!(ballot_id)

    socket
    |> assign(:page_title, "View Ballot: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("publish", _params, socket) do
    %{ballot: ballot} = socket.assigns

    case Ballots.publish_ballot(ballot) do
      {:ok, ballot} ->
        {:noreply, assign(socket, :ballot, ballot)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not publish ballot.")}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="my-6">
        <.back navigate={~p"/ballots"}>Back to ballots</.back>
      </div>

      <div class="my-6">
        <.link navigate={~p"/ballots/#{@ballot}/edit"}>Edit</.link>
      </div>

      <div class="my-6">
        <%= if @ballot.published_at do %>
          Published at: <%= @ballot.published_at %>
        <% else %>
          <.button phx-click="publish">Publish</.button>
        <% end %>
      </div>

      <p>Some ballot detail page.</p>
      <p id="ballot-question-title"><%= @ballot.question_title %></p>
      <div>
        <pre><%= inspect(@ballot, pretty: true) %></pre>
      </div>
    </div>
    """
  end
end
