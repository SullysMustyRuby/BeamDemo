defmodule BeamDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BeamDemo.Utils.SettingStore,
      BeamDemo.Repo,
      # Start the Telemetry supervisor
      BeamDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BeamDemo.PubSub},
      BeamDemo.Accounts.UserStore,
      BeamDemo.Accounts.UserTokenStore,
      BeamDemo.Accounts.AddressStore,
      BeamDemo.Utils.StateCodeStore,
      # Start the Endpoint (http/https)
      BeamDemoWeb.Endpoint
      # Start a worker by calling: BeamDemo.Worker.start_link(arg)
      # {BeamDemo.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeamDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
