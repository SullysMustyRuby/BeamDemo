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

    delete "/users/log_out", UserSessionController, :delete
    # get "/db_users/confirm", DbUserConfirmationController, :new
    # post "/db_users/confirm", DbUserConfirmationController, :create
    # get "/db_users/confirm/:token", DbUserConfirmationController, :edit
    # post "/db_users/confirm/:token", DbUserConfirmationController, :update
  end

  scope "/", BeamDemoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create

    # get "/db_users/reset_password", DbUserResetPasswordController, :new
    # post "/db_users/reset_password", DbUserResetPasswordController, :create
    # get "/db_users/reset_password/:token", DbUserResetPasswordController, :edit
    # put "/db_users/reset_password/:token", DbUserResetPasswordController, :update
  end

  scope "/", BeamDemoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :default, on_mount: BeamDemoWeb.UserAuthLive do
      live "/guess", WrongLive
    end

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    post "/users/settings", UserSettingsController, :update
    # get "/db_users/settings/confirm_email/:token", DbUserSettingsController, :confirm_email
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
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
