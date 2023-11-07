defmodule I3Status.InputsManager do
  @moduledoc """
  TODO: I3Status.InputsManager
  """

  use Task

  @registry I3Status.BlockRegistry

  ## Public API

  def start_link(_opts) do
    Task.start_link(__MODULE__, :run, [])
  end

  ## Task callback

  def run() do
    line = IO.read(:stdio, :line)

    # ,{"name":"battery","button":1,"modifiers":[],"x":1623,"y":1071,"relative_x":23,"relative_y":12,"output_x":1623,"output_y":1071,"width":147,"height":21}
    command =
      line
      |> String.trim_leading(",")
      |> String.trim_trailing("\n")

    case command do
      "[" -> :ok
      _ -> command |> Poison.decode!() |> send_to_block()
    end

    run()
  end

  ## Helpers

  defp send_to_block(event) do
    name = event["instance"] || event["name"]

    case name do
      nil -> :ignore
      _ -> GenServer.cast({:via, Registry, {@registry, name}}, {:click, event})
    end
  end
end
