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
    end
  end

  ## Internal behaviour

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:via, Registry, {@registry, opts.name}})
  end

  ## GenServer behaviour

  @impl true
  def init(opts) do
    send(self(), :tick_update)
    {:ok, opts}
  end

  @impl true
  def handle_info(:tick_update, state) do
    %{name: name, mod: mod, interval: interval} = state

    value = mod.handle_update(state)
    GenServer.cast(I3Status.Bar, {:update, name, value})

    Process.send_after(self(), :tick_update, interval)

    {:noreply, state}
  end
end
