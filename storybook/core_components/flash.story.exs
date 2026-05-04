defmodule Storybook.Components.CoreComponents.Flash do
  use PhoenixStorybook.Story, :component

  def function, do: &FlickWeb.CoreComponents.flash/1
  def imports, do: [{FlickWeb.CoreComponents, show: 1, button: 1}]
  def render_source, do: :function

  def template do
    """
    <div>
      <.button phx-click={show("#:variation_id")}>
        Trigger flash
      </.button>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :info,
        description: "Info message",
        attributes: %{
          kind: :info,
          hidden: true,
          title: "Did you know?"
        },
        slots: ["Flash message"]
      },
      %Variation{
        id: :error,
        description: "Error message",
        attributes: %{
          kind: :error,
          hidden: true,
          title: "Oops!"
        },
        slots: ["Sorry, it just crashed"]
      }
    ]
  end
end
