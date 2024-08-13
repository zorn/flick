defmodule FlickWeb.Ballots.ViewerLive do
  @moduledoc """
  A live view that presents a the detail presentation for a
  `Flick.RankedVoting.Ballot` entity.
  """

  use FlickWeb, :live_view

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.Vote
  alias Flick.RankedVoting.RankedAnswer

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"url_slug" => url_slug, "secret" => secret} = params

    ballot = RankedVoting.get_ballot_by_url_slug_and_secret!(url_slug, secret)
    votes = RankedVoting.list_votes_for_ballot_id(ballot.id)

    socket
    |> assign(:page_title, "View Ballot: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> assign(:votes, votes)
    |> assign(:vote_forms, %{})
    |> ok()
  end

  # @spec assign_vote_forms(Socket.t(), [Vote.t()]) :: Socket.t()
  # defp assign_vote_forms(socket, votes) when is_list(votes) do
  #   vote_forms =
  #     Enum.reduce(votes, %{}, fn vote, acc ->
  #       Map.put(acc, vote.id, to_form(RankedVoting.change_vote(vote, %{})))
  #     end)

  #   assign(socket, vote_forms: vote_forms, show_vote_form_ids: [])
  # end

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

  def handle_event("present-inline-editor", %{"vote-id" => vote_id}, socket) do
    # To present the inline editor we need only create the form and store it in
    # the assigns.
    socket
    |> update(:vote_forms, fn current_vote_forms ->
      vote = Enum.find(socket.assigns.votes, &(&1.id == vote_id))

      if vote do
        vote_form = to_form(RankedVoting.change_vote(vote, %{}))
        Map.put(current_vote_forms, vote_id, vote_form)
      else
        current_vote_forms
      end
    end)
    |> noreply()
  end

  def handle_event("dismiss-inline-editor", %{"vote-id" => vote_id}, socket) do
    # To dismiss the inline editor we need only remove the form from the assigns.

    socket
    |> update(:vote_forms, fn current_vote_forms ->
      Map.delete(current_vote_forms, vote_id)
    end)
    |> noreply()
  end

  def handle_event("validate", params, socket) do
    %{"vote_id" => vote_id, "weight" => weight} = params

    socket
    |> update(:vote_forms, fn current_vote_forms ->
      vote = Enum.find(socket.assigns.votes, &(&1.id == vote_id))

      dbg(current_vote_forms)

      if vote do
        vote_form =
          vote
          |> RankedVoting.change_vote(%{weight: weight}, action: :validate)
          |> to_form()
          |> dbg()

        Map.put(current_vote_forms, vote_id, vote_form)
      end
    end)
    |> noreply()
  end

  def handle_event("save", params, socket) do
    dbg(params)

    # The `params` will include a `vote_id` but we need to verify that it aligns with the ballot being viewed by this

    socket
    |> noreply()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="prose">
        <h2>Ballot Admin</h2>

        <dl>
          <dt class="font-bold">Question Title</dt>
          <dd id="ballot-question-title" class="pb-4"><%= @ballot.question_title %></dd>
          <dt class="font-bold">Possible Answers</dt>
          <dd id="ballot-possible-answers" class="pb-4"><%= @ballot.possible_answers %></dd>
          <dt class="font-bold">URL Slug</dt>
          <dd id="ballot-url-slug" class="pb-4"><%= @ballot.url_slug %></dd>
        </dl>
        <.button :if={RankedVoting.can_update_ballot?(@ballot)} id="edit-ballot-button">
          <.link
            navigate={~p"/#{@ballot.url_slug}/#{@ballot.id}/edit"}
            class="text-white no-underline"
          >
            Edit Ballot
          </.link>
        </.button>
      </div>

      <div class="my-6">
        <%= if @ballot.published_at do %>
          <div class="prose">
            <p>This ballot was published at: <%= @ballot.published_at %></p>

            <p>
              You can invite people to vote using the URL:
              <.link navigate={~p"/#{@ballot.url_slug}"}>
                <%= URI.append_path(@socket.host_uri, "/#{@ballot.url_slug}") %>
              </.link>
            </p>
          </div>
        <% else %>
          <.button phx-click="publish" id="publish-ballot-button">Publish</.button>
        <% end %>
      </div>

      <div class="prose">
        <h3>Vote Results</h3>
        <p>A table showing the tallied vote results would go here.</p>
      </div>

      <div class="prose">
        <h3>Votes (Add Total Count)</h3>
      </div>

      <.table id="votes" rows={@votes} row_id={&"vote-row-#{&1.id}"}>
        <:col :let={vote} label="ID">
          <%!-- This will be replace with name in the future. --%>
          <%!-- https://github.com/zorn/flick/issues/34 --%>
          <%= vote.id %>
        </:col>
        <:col :let={vote} label="Weight">
          <div :if={!form_for_vote(@vote_forms, vote)}>
            <%= vote.weight %> &nbsp;
            <%!-- TODO: As the user clicks `Edit` we should focus the form input. --%>
            <.link phx-click="present-inline-editor" phx-value-vote-id={vote.id} class="underline">
              Edit
            </.link>
          </div>
          <.form
            :let={form}
            :if={form_for_vote(@vote_forms, vote)}
            for={form_for_vote(@vote_forms, vote)}
            phx-change="validate"
            phx-submit="save"
          >
            <input type="hidden" name="vote_id" , value={vote.id} />
            <input
              type="text"
              name="weight"
              value={Phoenix.HTML.Form.input_value(form, :weight)}
              class="w-12 rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 border-zinc-300 focus:border-zinc-400"
              autofocus
            />
            <.button>Save</.button>
            <.link phx-click="dismiss-inline-editor" phx-value-vote-id={vote.id} class="underline">
              Cancel
            </.link>
          </.form>
        </:col>
        <:col :let={vote} :if={show_answer(@ballot, 0)} label="First Preference">
          <%= answer_at_index(vote, 0) %>
        </:col>
        <:col :let={vote} :if={show_answer(@ballot, 1)} label="Second Preference">
          <%= answer_at_index(vote, 1) %>
        </:col>
        <:col :let={vote} :if={show_answer(@ballot, 2)} label="Third Preference">
          <%= answer_at_index(vote, 2) %>
        </:col>
        <:col :let={vote} :if={show_answer(@ballot, 3)} label="Fourth Preference">
          <%= answer_at_index(vote, 3) %>
        </:col>
        <:col :let={vote} :if={show_answer(@ballot, 4)} label="Fifth Preference">
          <%= answer_at_index(vote, 4) %>
        </:col>
      </.table>
    </div>
    """
  end

  # defp present_inline_editor(js \\ %JS{}, vote) do
  #   js
  #   |> JS.hide(to: "#weight-view-cell-content-#{vote.id}")
  #   |> JS.show(to: "#weight-editor-cell-content-#{vote.id}")
  #   |> JS.focus(to: "#weight-editor-cell-content-#{vote.id} input")
  # end

  # defp dismiss_inline_editor(js \\ %JS{}, vote) do
  #   js
  #   |> JS.hide(to: "#weight-editor-cell-content-#{vote.id}")
  #   |> JS.show(to: "#weight-view-cell-content-#{vote.id}")
  # end

  defp form_for_vote(vote_forms, vote) do
    Map.get(vote_forms, vote.id)
  end

  defp show_answer(%Ballot{} = ballot, index) when is_integer(index) do
    RankedVoting.allowed_answer_count_for_ballot(ballot) > index
  end

  defp answer_at_index(%Vote{} = vote, index) when is_integer(index) do
    %RankedAnswer{value: value} = Enum.at(vote.ranked_answers, index)
    value
  end
end
