defmodule I3Status.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    blocks = [
      I3Status.Blocks.Battery,
      I3Status.Blocks.DateBlock
    ]

    children = [
      {Registry, keys: :unique, name: I3Status.BlockRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: I3Status.BlockSupervisor},
      {I3Status.Bar, blocks: blocks}
    ]

    IO.puts(:stderr, "i3status is starting...")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: I3Status.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
