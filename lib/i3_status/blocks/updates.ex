defmodule I3Status.Blocks.Updates do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.Updates
  """

  use I3Status.Block, name: "updates", interval: :timer.hours(1)

  def setup(state) do
    I3Status.Block.emit(state.name, %{full_text: " updating databases"})
    {:ok, state}
  end

  def handle_update(state) do
    # Update the local packages db
    with {_, 0} <- System.cmd("yay", ["-Sy"]),
         # List updates
         {result, 0} <- System.cmd("yay", ["-Qu"]) do
      count = result |> String.split("\n", trim: true) |> length()

      case count do
        0 ->
          %{full_text: " System up to date", short_text: " up to date", color: "success"}

        _ ->
          %{
            full_text: " #{count} updates found",
            short_text: " #{count} updates",
            color: "warning"
          }
      end
    else
      _ -> %{full_text: " error when fetching updates", short_text: " error", color: "danger"}
    end
    |> then(&{:emit, &1, state})
  end
end
