defmodule FlickWeb.Ballots.ViewerLive do
  @moduledoc """
  A live view that presents a the detail presentation for a
  `Flick.RankedVoting.Ballot` entity.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"url_slug" => url_slug, "secret" => secret} = params

    ballot = RankedVoting.get_ballot_by_url_slug_and_secret!(url_slug, secret)

    socket
    |> assign(:page_title, "View Ballot: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("publish", _params, socket) do
    %{ballot: ballot} = socket.assigns

    case RankedVoting.publish_ballot(ballot) do
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
      <div class="prose">
        <h2>Ballot Admin</h2>

        <dl>
          <dt class="font-bold">Question Title</dt>
          <dd class="pb-4"><%= @ballot.question_title %></dd>
          <dt class="font-bold">Possible Answers</dt>
          <dd class="pb-4"><%= @ballot.possible_answers %></dd>
          <dt class="font-bold">URL Slug</dt>
          <dd class="pb-4"><%= @ballot.url_slug %></dd>
        </dl>
        <.button>
          <.link
            navigate={~p"/#{@ballot.url_slug}/#{@ballot.id}/edit"}
            class="text-white no-underline"
          >
            Edit Ballot
          </.link>
        </.button>
      </div>

      <div class="my-6"></div>

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
