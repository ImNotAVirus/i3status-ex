defmodule I3Status.Blocks.RAMBlock do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.RAMBlock
  """

  use I3Status.Block, name: "ram", interval: :timer.seconds(1)

  def handle_update(state) do
    data = :memsup.get_system_memory_data()
    total = data[:total_memory] / Integer.pow(1024, 3)
    available = data[:available_memory] / Integer.pow(1024, 3)
    used = total - available

    used = Float.ceil(used, 1)
    total = Float.ceil(total, 1)

    block = %{
      full_text: " #{used}Gi / #{total}Gi",
      min_width: " #{total}Gi / #{total}Gi",
      markup: "pango"
    }

    {:emit, block, state}
  end
end
