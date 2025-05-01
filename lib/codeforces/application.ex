defmodule Codeforces.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CodeforcesWeb.Telemetry,
      Codeforces.Repo,
      {DNSCluster, query: Application.get_env(:codeforces, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Codeforces.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Codeforces.Finch},
      # Start a worker by calling: Codeforces.Worker.start_link(arg)
      # {Codeforces.Worker, arg},
      # Start to serve requests, typically the last entry
      CodeforcesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Codeforces.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CodeforcesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
