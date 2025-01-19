defmodule FlickWeb.Ballots.ViewerLive do
  @moduledoc """
  A live view that presents a the detail presentation for a
  `Flick.RankedVoting.Ballot` entity.

  TODO: Add docs about the socket assign state we keep and why. Maybe as a Elixir type?
  """

  use FlickWeb, :live_view

  alias Flick.DateTimeFormatter
  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.RankedAnswer
  alias Flick.RankedVoting.Vote

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{"url_slug" => url_slug, "secret" => secret} = params

    ballot = RankedVoting.get_ballot_by_url_slug_and_secret!(url_slug, secret)
    time_zone = get_connect_params(socket)["time_zone"] || "UTC"

    socket
    |> assign(:page_title, "View Ballot: #{ballot.question_title}")
    |> assign(:ballot, ballot)
    |> assign(:time_zone, time_zone)
    |> assign_votes()
    |> assign(:vote_forms, %{})
    |> ok()
  end

  defp assign_votes(socket) do
    %{ballot: ballot} = socket.assigns
    votes = RankedVoting.list_votes_for_ballot_id(ballot.id)
    ballot_results_report = RankedVoting.get_ballot_results_report(ballot.id)
    assign(socket, votes: votes, ballot_results_report: ballot_results_report)
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

  def handle_event("close", _params, socket) do
    %{ballot: ballot} = socket.assigns

    case RankedVoting.close_ballot(ballot) do
      {:ok, ballot} ->
        {:noreply, assign(socket, :ballot, ballot)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not close ballot.")}
    end
  end

  def handle_event("present-inline-editor", %{"vote-id" => vote_id}, socket) do
    vote = assert_vote_id(socket, vote_id)

    # To present the inline editor we need only create the form and store it in
    # the assigns.
    socket
    |> update(:vote_forms, fn current_vote_forms ->
      vote_form = to_form(RankedVoting.change_vote(vote, %{}))
      Map.put(current_vote_forms, vote_id, vote_form)
    end)
    |> noreply()
  end

  def handle_event("dismiss-inline-editor", %{"vote-id" => vote_id}, socket) do
    vote = assert_vote_id(socket, vote_id)

    # To dismiss the inline editor we need only remove the form from the assigns.
    socket
    |> update(:vote_forms, fn current_vote_forms ->
      Map.delete(current_vote_forms, vote.id)
    end)
    |> noreply()
  end

  def handle_event("validate", params, socket) do
    %{"vote_id" => vote_id, "weight" => weight} = params
    vote = assert_vote_id(socket, vote_id)

    socket
    |> update(:vote_forms, fn current_vote_forms ->
      change = %{weight: weight}
      vote_form = to_form(RankedVoting.change_vote(vote, change, action: :validate))
      Map.put(current_vote_forms, vote_id, vote_form)
    end)
    |> noreply()
  end

  def handle_event("save", params, socket) do
    %{"vote_id" => vote_id, "weight" => weight} = params
    vote = assert_vote_id(socket, vote_id)
    %{ballot: ballot} = socket.assigns

    case RankedVoting.update_vote(ballot, vote, %{weight: weight}) do
      {:ok, _vote} ->
        socket
        |> update(:vote_forms, fn current_vote_forms ->
          Map.delete(current_vote_forms, vote_id)
        end)
        # FIXME: This is a expensive, and we might consider a more efficient
        # solution, maybe using streams?
        |> assign_votes()
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Could not update vote.")
        |> update(:vote_forms, fn current_vote_forms ->
          Map.put(current_vote_forms, vote_id, to_form(changeset))
        end)
        |> noreply()
    end
  end

  @impl Phoenix.LiveView
  def render(%{ballot: %Ballot{published_at: nil}} = assigns) do
    ~H"""
    <.shared_header />

    <div class="mt-8 prose">
      <h3 class="mb-0">Edit Ballot</h3>
      <p>
        Your ballot was created at {formatted_datetime(@ballot.inserted_at, @time_zone)}. The ballot is not yet published and can be edited.
      </p>
    </div>

    <div class="mt-8 bg-slate-100 rounded-lg p-4">
      <dl>
        <dt class="font-bold">Question Title</dt>
        <dd id="ballot-question-title" class="pb-4">{@ballot.question_title}</dd>
        <dt class="font-bold">Description</dt>

        <dd id="ballot-description" class="pb-4 prose">
          {@ballot.description && raw(Flick.Markdown.render_to_html(@ballot.description))}
        </dd>
        <dt class="font-bold">Possible Answers</dt>
        <dd id="ballot-possible-answers" class="pb-4">{@ballot.possible_answers}</dd>
        <dt class="font-bold">URL Slug</dt>
        <dd id="ballot-url-slug" class="pb-4">{@ballot.url_slug}</dd>
      </dl>
      <.link
        :if={RankedVoting.can_update_ballot?(@ballot)}
        navigate={~p"/ballot/#{@ballot.url_slug}/#{@ballot.secret}/edit"}
        class="text-white no-underline"
      >
        <.button id="edit-ballot-button">
          Edit Ballot
        </.button>
      </.link>
    </div>

    <div class="mt-8 prose">
      <h3 class="mb-0">Publish Ballot</h3>
      <p class="mb-2">Once you are satisfied with your ballot, hit the publish button below.</p>

      <.button phx-click="publish" id="publish-ballot-button">Publish Ballot</.button>
    </div>
    """
  end

  def render(%{ballot: %Ballot{closed_at: nil}} = assigns) do
    ~H"""
    <.shared_header />

    <div class="mt-8 prose">
      <h3 class="mb-0">Ballot is Published!</h3>
      <p>
        Your ballot was published at {formatted_datetime(@ballot.published_at, @time_zone)}. Use the URL below to invite people to vote!
      </p>
      <.link navigate={~p"/ballot/#{@ballot.url_slug}"}>
        {URI.append_path(@socket.host_uri, "/ballot/#{@ballot.url_slug}")}
      </.link>

      <p class="mb-2">
        When you no longer want to accept votes close the ballot using the button below.
      </p>

      <.button phx-click="close" id="close-ballot-button">Close Ballot</.button>
    </div>

    <div class="prose mb-8">
      <.vote_results
        ballot_results_report={@ballot_results_report}
        votes={@votes}
        title="Early Results"
      />

      <.votes_table ballot={@ballot} votes={@votes} vote_forms={@vote_forms} />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.shared_header />

    <div class="mt-8 prose">
      <h3 class="mb-0">Ballot is Closed</h3>
      <p>
        Your ballot was closed at {formatted_datetime(@ballot.closed_at, @time_zone)}. Result totals can be viewed by everyone at:
      </p>
      <.link navigate={~p"/ballot/#{@ballot.url_slug}/results"}>
        {URI.append_path(@socket.host_uri, "/ballot/#{@ballot.url_slug}/results")}
      </.link>
    </div>
    <div class="prose mb-8">
      <.vote_results
        ballot_results_report={@ballot_results_report}
        votes={@votes}
        title="Final Results"
      />

      <.votes_table ballot={@ballot} votes={@votes} />
    </div>
    """
  end

  attr :ballot_results_report, :list, required: true
  attr :votes, :list, required: true
  attr :title, :string, default: "Results"

  defp vote_results(assigns) do
    ~H"""
    <div>
      <h3>{@title} ({length(@votes)} votes received)</h3>
      <ol>
        <%= for %{points: points, value: answer} <- @ballot_results_report do %>
          <li>{answer}: {points} points</li>
        <% end %>
      </ol>
    </div>
    """
  end

  attr :ballot, Ballot, required: true
  attr :votes, :list, required: true
  attr :vote_forms, :map, default: nil

  defp votes_table(assigns) do
    ~H"""
    <.table id="votes" rows={@votes} row_id={&"vote-row-#{&1.id}"}>
      <:col :let={vote} label="Name">
        {vote.full_name || "No Name"}
      </:col>
      <:col :let={vote} label="Weight">
        <.weight_label
          vote={vote}
          vote_forms={@vote_forms}
          enable_inline_editor={!is_nil(@vote_forms)}
        />
        <.weight_form vote={vote} vote_forms={@vote_forms} />
      </:col>
      <:col
        :let={vote}
        :if={show_answer(@ballot, 0)}
        label="First (5pts)"
        title="First Preference is worth 5pts."
      >
        {answer_at_index(vote, 0)}
      </:col>
      <:col
        :let={vote}
        :if={show_answer(@ballot, 1)}
        label="Second (4pts)"
        title="Second Preference is worth 4pts."
      >
        {answer_at_index(vote, 1)}
      </:col>
      <:col
        :let={vote}
        :if={show_answer(@ballot, 2)}
        label="Third (3pts)"
        title="Third Preference is worth 3pts."
      >
        {answer_at_index(vote, 2)}
      </:col>
      <:col
        :let={vote}
        :if={show_answer(@ballot, 3)}
        label="Fourth (2pts)"
        title="Fourth Preference is worth 2pts."
      >
        {answer_at_index(vote, 3)}
      </:col>
      <:col
        :let={vote}
        :if={show_answer(@ballot, 4)}
        label="Fifth (1pt)"
        title="Fifth Preference is worth 1pt."
      >
        {answer_at_index(vote, 4)}
      </:col>
    </.table>
    """
  end

  attr :vote, Vote, required: true
  attr :vote_forms, :map, required: true
  attr :enable_inline_editor, :boolean, default: true

  defp weight_label(%{enable_inline_editor: false} = assigns) do
    ~H"""
    <div>{@vote.weight}</div>
    """
  end

  defp weight_label(assigns) do
    ~H"""
    <div :if={@vote_forms && !form_for_vote(@vote_forms, @vote)}>
      {@vote.weight} &nbsp;
      <.link phx-click="present-inline-editor" phx-value-vote-id={@vote.id} class="underline">
        Edit
      </.link>
    </div>
    """
  end

  attr :vote, Vote, required: true
  attr :vote_forms, :map, required: true

  defp weight_form(assigns) do
    ~H"""
    <.form
      :let={form}
      :if={@vote_forms && form_for_vote(@vote_forms, @vote)}
      for={form_for_vote(@vote_forms, @vote)}
      phx-change="validate"
      phx-submit="save"
    >
      <input type="hidden" name="vote_id" , value={@vote.id} />
      <%!-- TODO: In the future we should draw red outline here when invalid. --%>
      <%!-- https://github.com/zorn/flick/issues/37 --%>
      <input
        type="text"
        name="weight"
        value={Phoenix.HTML.Form.input_value(form, :weight)}
        class="w-16 rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 border-zinc-300 focus:border-zinc-400"
        autofocus
      />
      <.button>Save</.button>
      <.link phx-click="dismiss-inline-editor" phx-value-vote-id={@vote.id} class="underline">
        Cancel
      </.link>
    </.form>
    """
  end

  defp shared_header(assigns) do
    ~H"""
    <div class="prose">
      <h2 class="mb-0">Ballot Admin</h2>

      <p>This page is where you'll edit, publish, tally and close your ballot.</p>

      <h3 class="mb-0">Bookmark This Page</h3>

      <p>
        This site does not use registered accounts. To return to this ballot admin page you'll need to full URL. Be sure to bookmark it now.
      </p>
    </div>
    """
  end

  defp assert_vote_id(socket, vote_id) do
    # Helper for events that are accepting a `vote_id` parameter. If the
    # frontend sends us a `vote_id` that is not known to this instance of the
    # live view, crash -- they are sus.
    %Vote{id: ^vote_id} = Enum.find(socket.assigns.votes, &(&1.id == vote_id))
  end

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

  @spec formatted_datetime(DateTime.t(), String.t()) :: String.t()
  defp formatted_datetime(date_time, time_zone) do
    case DateTimeFormatter.display_string(date_time, time_zone) do
      formatted_date_time when is_binary(formatted_date_time) ->
        formatted_date_time

      {:error, _reason} ->
        # If we can not get proper formatted string let's just return something.
        DateTime.to_string(date_time)
    end
  end
end
