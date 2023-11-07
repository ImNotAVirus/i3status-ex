defmodule I3Status.Blocks.CPUBlock do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.CPUBlock
  """

  use I3Status.Block, name: "cpu", interval: :timer.seconds(1)

  def handle_update(state) do
    percent = Float.floor(:cpu_sup.util(), 1)

    block = %{
      full_text: " #{percent}%",
      min_width: " 99.9%",
      markup: "pango"
    }

    {:emit, block, state}
  end
end
