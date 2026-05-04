defmodule FlickWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FlickWeb, :html

  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  @spec app(Socket.assigns()) :: Rendered.t()
  def app(assigns) do
    ~H"""
    <%!-- Logo and Navigation --%>
    <section class="bg-gradient-to-r from-teal-500 to-blue-500 py-4">
      <FlickWeb.UI.page_column>
        <div class="text-4xl">
          <div class="flex justify-between items-center">
            <.link
              class="font-bold text-white drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,0.8)]"
              href={~p"/"}
            >
              RankedVote<span class="text-2xl">.app</span>
            </.link>
            <.link navigate={~p"/ballot/new"} class="flex items-center">
              <.button class="shadow-none">
                Create Ballot
              </.button>
            </.link>
          </div>
        </div>
      </FlickWeb.UI.page_column>
    </section>

    <%!-- Page Content --%>
    <section>
      <FlickWeb.UI.page_column class="my-4">
        <.flash_group flash={@flash} />
        {render_slot(@inner_block)}
      </FlickWeb.UI.page_column>
    </section>

    <%!-- Footer --%>
    <section class="mt-8">
      <hr class="mb-4" />
      <FlickWeb.UI.page_column class="text-center">
        <div class="prose">
          <a href="https://github.com/zorn/flick"> GitHub Project </a>
          &bull; <a href="https://updown.io/wwis">Uptime</a>
          &bull; <a href="mailto:mike@mikezornek.com">Contact Site Admin</a>
        </div>
      </FlickWeb.UI.page_column>
    </section>
    """
  end
end
