# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule FlickWeb.Router do
  use FlickWeb, :router

  import PhoenixStorybook.Router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlickWeb.Layouts, :root}
    plug :protect_from_forgery

    # Tailwind uses SVG data URLs for icons,
    # so we need to allow them with `img-src`.
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
    #
    # To avoid web console issues with Phoenix Storybook we've added
    # `style-src 'self' 'unsafe-inline'` which feels unfortunate and
    # might be reconsidered.
    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' https://plausible.io; connect-src 'self' https://plausible.io"
    }
  end

  pipeline :admin do
    plug :basic_auth, Application.compile_env(:flick, :basic_auth)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    storybook_assets()
  end

  scope "/admin", FlickWeb do
    pipe_through [:browser, :admin]

    live "/ballots", Ballots.IndexLive, :index
  end

  scope "/", FlickWeb do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/ballot/new", Ballots.EditorLive, :new
    live "/ballot/:url_slug/results", Vote.ResultsLive, :index
    live "/ballot/:url_slug/:secret/edit", Ballots.EditorLive, :edit
    live "/ballot/:url_slug/:secret", Ballots.ViewerLive, :edit
    live "/ballot/:url_slug", Vote.VoteCaptureLive, :new

    live_storybook "/storybook", backend_module: Elixir.FlickWeb.Storybook
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:flick, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlickWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
