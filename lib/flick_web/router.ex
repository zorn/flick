defmodule FlickWeb.Router do
  use FlickWeb, :router

  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlickWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug :basic_auth, Application.compile_env(:flick, :basic_auth)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/admin", FlickWeb do
    pipe_through [:browser, :admin]

    live "/ballots", Ballots.IndexLive, :index
  end

  scope "/", FlickWeb do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/create-ballot", Ballots.EditorLive, :new
    live "/:url_slug/:secret", Ballots.ViewerLive, :edit
    live "/:url_slug/:secret/edit", Ballots.EditorLive, :edit
    live "/:url_slug", Vote.VoteCaptureLive, :new
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
