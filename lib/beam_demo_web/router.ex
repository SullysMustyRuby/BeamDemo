defmodule BeamDemoWeb.Router do
  use BeamDemoWeb, :router

  import BeamDemoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BeamDemoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BeamDemoWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  ## Authentication routes

  scope "/", BeamDemoWeb do
    pipe_through [:browser]

    delete "/log_out", UserSessionController, :delete
  end

  scope "/", BeamDemoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", BeamDemoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :default, on_mount: BeamDemoWeb.UserAuthLive do
      live "/guess", WrongLive
      live "/address", AddressLive.Index, :index
      live "/address/new", AddressLive.Index, :new
      live "/address/:uuid/edit", AddressLive.Index, :edit

      live "/address/:uuid/", AddressLive.Show, :show
      live "/address/:uuid/show/edit", AddressLive.Show, :edit

      live "/settings", SettingLive.Index, :index
      live "/settings/new", SettingLive.Index, :new
      live "/settings/:name/edit", SettingLive.Index, :edit

      live "/settings/:name/", SettingLive.Show, :show
      live "/settings/:name/show/edit", SettingLive.Show, :edit
    end

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    post "/users/settings", UserSettingsController, :update
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BeamDemoWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  # if Mix.env() == :dev do
  #   scope "/dev" do
  #     pipe_through :browser

  #     forward "/mailbox", Plug.Swoosh.MailboxPreview
  #   end
  # end
end
