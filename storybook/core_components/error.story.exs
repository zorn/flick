defmodule Storybook.Components.CoreComponents.Error do
  use PhoenixStorybook.Story, :component

  def function, do: &FlickWeb.CoreComponents.error/1
  def imports, do: [{FlickWeb.CoreComponents, button: 1}]

  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        description: "Typical error message",
        slots: [
          """
          Obviously, something went wrong ...
          """
        ]
      },
      %Variation{
        id: :try_again,
        slots: [
          """
          Obviously, something went wrong ...
          <div class="mt-2">
            <.button class="bg-rose-600 hover:bg-rose-700">Try again</.button>
          </div>
          """
        ]
      }
    ]
  end
end
