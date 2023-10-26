defmodule I3Status.Blocks.DateBlock do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.DateBlock
  """

  use I3Status.Block, name: "date", interval: :timer.seconds(1)

  ## Block behaviour

  def handle_update(_state) do
    %{full_text: " #{now_to_string()}"}
  end

  ## Private helpers

  defp now_to_string() do
    {{year, month, day}, {hour, minute, second}} = :calendar.local_time()
    "#{year}-#{zero_pad(month)}-#{zero_pad(day)} #{zero_pad(hour)}:#{zero_pad(minute)}:#{zero_pad(second)}"
  end

  defp zero_pad(number) do
    number
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end
end
