defmodule I3Status.Bar do
  @moduledoc """
  TODO: Documentation for I3Status.Bar
  """

  use GenServer

  ## Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## GenServer behaviour

  @impl true
  def init(opts) do
    blocks = Keyword.fetch!(opts, :blocks)

    # Start blocks
    block_names =
      blocks
      |> Enum.with_index()
      |> Enum.map(fn {block, index} ->
        {:ok, pid} =
          DynamicSupervisor.start_child(I3Status.BlockSupervisor, {block, offset: index})

        ## FIXME: Clean this lol
        :sys.get_state(pid).name
      end)

    {:ok, %{blocks: block_names, states: %{}}, {:continue, :init_loop}}
  end

  @impl true
  def handle_continue(:init_loop, state) do
    # Send the header so that i3bar knows we want to use JSON:
    emit(%{version: 1})
    emit("\n")

    # Begin the endless array.
    emit("[\n")

    # We send an empty first array of blocks to make the loop simpler:
    emit("[],")

    {:noreply, state, {:continue, :first_update}}
  end

  @impl true
  def handle_continue(:first_update, %{blocks: blocks} = state) do
    initial_data =
      blocks
      |> Enum.map(fn name ->
        receive do
          {:"$gen_cast", {:update, ^name, value}} -> Map.put(value, :name, name)
        after
          5000 -> raise "timeout"
        end
      end)

    initial_data
    |> build()
    |> emit()

    emit(",")

    states =
      initial_data
      |> Enum.group_by(& &1.name)
      |> Map.new(fn {key, [value]} -> {key, value} end)

    {:noreply, Map.put(state, :states, states)}
  end

  @impl true
  def handle_cast({:update, name, value}, state) do
    %{blocks: blocks, states: states} = state
    states = Map.put(states, name, Map.put(value, :name, name))

    blocks
    |> Enum.map(&Map.fetch!(states, &1))
    |> build()
    |> emit()

    emit(",")

    {:noreply, Map.put(state, :states, states)}
  end

  ## Private helpers

  defp emit(data) when is_binary(data) do
    IO.write(data)
  end

  defp emit(data) do
    data |> Poison.encode!() |> IO.write()
  end

  defp build(blocks) do
    bg_colors = Stream.cycle(["#562877", "#764C99"])
    normal_colors = Stream.cycle(["#CCCCCC", "#370140"])
    info_colors = Stream.cycle(["#007BFF", "#4BA2FF"])
    success_colors = Stream.cycle(["#28A745", "#34C455"])
    warning_colors = Stream.cycle(["#FFC107", "#FFD043"])
    danger_colors = Stream.cycle(["#EA2F42", "#FF3B3B"])

    color_tuples =
      Stream.zip([
        bg_colors,
        normal_colors,
        info_colors,
        success_colors,
        warning_colors,
        danger_colors
      ])

    separator = %{
      full_text: "<span font='14.5'></span>",
      separator: false,
      separator_block_width: 0,
      border_top: 0,
      border_bottom: 0,
      markup: "pango"
    }

    separators = Stream.repeatedly(fn -> separator end)

    blocks =
      blocks
      |> Enum.zip(color_tuples)
      |> Enum.map(fn {block, {bg_color, normal, info, success, warning, danger}} ->
        default = %{
          background: bg_color,
          separator: false,
          separator_block_width: 0,
          align: "center",
          min_width: block.full_text <> "  "
        }

        color =
          case Map.get(block, :color) do
            nil -> normal
            "info" -> info
            "success" -> success
            "warning" -> warning
            "danger" -> danger
            value -> value
          end

        default
        |> Map.merge(block)
        |> Map.put(:color, color)
      end)

    separator_colors = Stream.zip(bg_colors, Stream.drop(bg_colors, 1))

    separators =
      separators
      |> Enum.take(length(blocks))
      |> Enum.zip(separator_colors)
      |> Enum.map(fn {sep, {color1, color2}} ->
        sep
        |> Map.put(:color, color1)
        |> Map.put(:background, color2)
      end)
      |> then(fn [head | tail] -> [Map.delete(head, :background) | tail] end)

    separators
    |> Enum.zip(blocks)
    |> Enum.flat_map(&Tuple.to_list/1)
  end
end
