defmodule Protohackers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Protohackers.EchoServer,
      {Bandit, plug: Protohackers.Healthcheck, port: 80},
      {Task.Supervisor, name: Protohackers.TaskSupervisor, max_children: 10}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Protohackers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
