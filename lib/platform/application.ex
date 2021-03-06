defmodule Platform.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      ## TODO: Need to start the game server per game not here... but this is to test
      # worker(Game.Server, nil, restart: :temporary),
      # Platform.Worker.start_link(Game.Server),
      # {Platform.Worker, Game.Server},
      # Start the Ecto repository
      Platform.Repo,
      # Start the endpoint when the application starts
      PlatformWeb.Endpoint
      # Starts a worker by calling: Platform.Worker.start_link(arg)
      # {Platform.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Platform.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PlatformWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
