defmodule FlickWeb.IndexLive do
  @moduledoc """
  A live view for the root page of the app.

  Currently this view just redirects to the ballots index.
  """

  use FlickWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(page_title: "Home")
    |> ok()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="prose prose-p:leading-6 prose-li:my-0">
      <section id="welcome-copy">
        <p>
          Many traditional voting systems ask for a single choice per voter, and the winner is chosen based on the number of votes cast for any single choice.
        </p>

        <p>
          In a <strong>ranked vote</strong>, voters provide ranked preferences instead of selecting a single choice, which ultimately results in a <strong>better consensus outcome</strong>.
        </p>

        <p>
          This site helps people quickly create, run, and tally ranked voting ballots. It is free-to-use and open source. No accounts are required to create or vote on a ballot.
        </p>

        <p class="font-bold">How it works:</p>

        <ol>
          <li>
            <.link navigate={~p"/ballot/new"}>Create a ballot</.link>
            with a question and possible answers.
          </li>
          <li>Publish the ballot, creating a link to share with voters.</li>
          <li>Tally the votes and derive a winner with a point-based system.</li>
        </ol>
      </section>

      <section>
        <p class="font-bold">What is ranked voting good for?</p>

        <ul>
          <li>Pick a book for a book club.</li>
          <li>Select a movie for family night.</li>
          <li>Choose a vacation destination for a large group.</li>
          <li>Decide on a new logo for a company.</li>
          <li>Prioritize technical debt projects.</li>
        </ul>
      </section>

      <section>
        <h3 class="mb-1">Free and Open Source</h3>

        <p>
          The open source project that powers this site is called <a href="https://github.com/zorn/flick">Flick</a>. It is written in
          <a href="https://elixir-lang.org/">Elixir</a>
          and <a href="https://www.phoenixframework.org/">Phoenix Live View</a>. It was initially built to help the
          <a href="https://elixirbookclub.github.io/website/">Elixir Book Club</a>
          pick books, but is shared with all to use and learn from.
        </p>
      </section>
    </div>
    """
  end
end
