defmodule FlickWeb.UI do
  @moduledoc """
  Domain-specific components to express the the UI for Flick.
  """

  use Phoenix.Component
  use FlickWeb, :verified_routes

  slot :inner_block, required: true
  attr :rest, :global

  def page_column(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4">
      <div {@rest}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
