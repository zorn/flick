defmodule FlickWeb.Storybook do
  @moduledoc """
  Provides a Phoenix Storybook configuration for the FlickWeb application.
  """

  use PhoenixStorybook,
    otp_app: :flick_web,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/storybook.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "flick-web"
end
