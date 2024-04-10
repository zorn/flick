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
    |> assign(:page_title, "View Ballot: #{ballot.title}")
    |> assign(:ballot, ballot)
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p>
        <.back navigate={~p"/ballots"}>Back to ballots</.back>
      </p>
      <p>Some ballot detail page.</p>
      <div>
        <pre><%= inspect(@ballot, pretty: true) %></pre>
      </div>
    </div>
    """
  end
end
