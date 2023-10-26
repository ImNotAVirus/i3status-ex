defmodule I3Status.Blocks.Battery do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.Battery
  """

  use I3Status.Block, name: "battery", interval: :timer.seconds(2)

  @bars 10

  ## /sys/class/power_supply/BAT0/energy_full
  ## /sys/class/power_supply/BAT0/energy_now
  ## /sys/class/power_supply/BAT0/status => Charging, Discharging

  def handle_update(state) do
    now = File.read!("/sys/class/power_supply/BAT0/energy_now")
    full = File.read!("/sys/class/power_supply/BAT0/energy_full")
    charging = File.read!("/sys/class/power_supply/BAT0/status")

    now = now |> String.trim() |> String.to_integer()
    full = full |> String.trim() |> String.to_integer()

    charge_icon = if charging == "Charging\n", do: "", else: " "
    percent = Float.floor(now * 100 / full, 1)

    # %{full_text: "#{charge_icon} ■■■■■■■■■▰ #{percent}%"}
    block = %{
      full_text: "#{charge_icon} #{bar(now, full)} #{percent}%",
      short_text: "#{charge_icon} #{percent}%",
      markup: "pango"
    }

    {:emit, block, state}
  end

  ## Private functions

  defp bar(now, full) do
    part = full / @bars
    {full, current, used} = do_bar(now, part, [])

    "#{full}#{current}#{used}"
  end

  defp do_bar(now, part, acc) when now > part do
    do_bar(now - part, part, ["■" | acc])
  end

  defp do_bar(now, part, acc) do
    current =
      case now > part / 2 do
        true -> ""
        false -> "<span fgcolor='#FFC107'>▰</span>"
      end

    full =
      case now > part / 2 do
        true -> :erlang.iolist_to_binary(["■" | acc])
        false -> :erlang.iolist_to_binary(acc)
      end
      |> then(&"<span fgcolor='#28A745'>#{&1}</span>")

    remaining = @bars - length(acc) - 1
    used = String.duplicate("▰", remaining)
    # used = "<span fgcolor='#EA2F42'>#{used}</span>"

    {full, current, used}
  end
end
