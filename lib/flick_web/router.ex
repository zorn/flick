# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule FlickWeb.Router do
  use FlickWeb, :router

  import PhoenixStorybook.Router
  import Plug.BasicAuth

  # Note: Sobelow's `Config.CSP` check only recognizes a CSP passed as a static
  # map to `put_secure_browser_headers`. We set the header dynamically in
  # `put_csp_headers` below (to inject a per-request nonce), so `Config.CSP` is
  # ignored in `.sobelow-conf`.
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlickWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers
    plug :put_csp_headers
  end

  pipeline :admin do
    plug :basic_auth, Application.compile_env(:flick, :basic_auth)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Sets our Content Security Policy header.
  #
  # We generate a per-request `nonce` so the small inline Plausible analytics
  # `<script>` in the root layout is allowed without opening up `script-src` to
  # `'unsafe-inline'`. The nonce is assigned to the conn so the layout can stamp
  # it onto that script tag.
  #
  # `style-src` allows `'unsafe-inline'` to avoid web console issues with
  # Phoenix Storybook, and `img-src` allows `data:` URLs because Tailwind uses
  # SVG data URLs for icons.
  #
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
  defp put_csp_headers(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64()

    csp =
      "default-src 'self'; " <>
        "img-src 'self' data:; " <>
        "style-src 'self' 'unsafe-inline'; " <>
        "script-src 'self' 'nonce-#{nonce}' https://plausible.io; " <>
        "connect-src 'self' https://plausible.io"

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", csp)
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

    live_storybook "/storybook", backend_module: FlickWeb.Storybook
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
