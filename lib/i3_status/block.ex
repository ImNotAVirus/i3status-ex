defmodule I3Status.Block do
  @moduledoc """
  TODO: Documentation for I3Status.Block
  """

  @behaviour GenServer

  @registry I3Status.BlockRegistry

  ## Public API

  @doc false
  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    interval = Keyword.get(opts, :interval, 1000)
    instance = Keyword.get(opts, :instance, false)

    quote location: :keep, generated: true do
      ## Public API

      def child_spec(opts) do
        block_opts = %{
          mod: __MODULE__,
          name: unquote(name),
          interval: unquote(interval),
          instance: unquote(instance)
        }

        proc_name =
          case {block_opts.name, block_opts.instance} do
            {name, false} -> name
            {name, true} -> "#{name}-#{System.unique_integer([:positive, :monotonic])}"
          end

        opts =
          block_opts
          |> Map.merge(Map.new(opts))
          |> Map.put(:name, proc_name)

        %{
          id: {__MODULE__, proc_name},
          start: {unquote(__MODULE__), :start_link, [opts]},
          restart: :permanent
        }
      end

      ## Block bahaviour

      def setup(state), do: {:ok, state}
      def handle_click(_event, state), do: {:noemit, state}

      defoverridable setup: 1, handle_click: 2
    end
  end

  def emit(name, value) do
    GenServer.cast(I3Status.Bar, {:update, name, value})
  end

  ## Internal behaviour

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:via, Registry, {@registry, opts.name}})
  end

  ## GenServer behaviour

  @impl true
  def init(state) do
    {:ok, new_state} = state.mod.setup(state)
    GenServer.cast(I3Status.Bar, {:started, self(), new_state})

    send(self(), :tick_update)

    {:ok, new_state}
  end

  @impl true
  def handle_info(:tick_update, state) do
    %{name: name, mod: mod, interval: interval} = state

    new_state =
      case mod.handle_update(state) do
        {:emit, value, state} ->
          emit(name, value)
          state

        {:noemit, state} ->
          state
      end

    Process.send_after(self(), :tick_update, interval)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:click, event}, state) do
    %{name: name, mod: mod} = state

    new_state =
      case mod.handle_click(event, state) do
        {:emit, value, state} ->
          emit(name, value)
          state

        {:noemit, state} ->
          state
      end

    {:noreply, new_state}
  end
end
