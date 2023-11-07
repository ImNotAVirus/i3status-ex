defmodule I3Status.Blocks.SpotifyBlock do
  @moduledoc """
  TODO: Documentation for I3Status.Blocks.SpotifyBlock
  """

  use I3Status.Block, name: "spotify", interval: :timer.seconds(2)

  @max_length 25

  ## Block behaviour

  def handle_update(state) do
    value =
      case System.cmd(spotify_script(), ["status"]) do
        {"Playing\n", 0} -> playing()
        {"Paused\n", 0} -> paused()
        _ -> not_started()
      end

    {:emit, value, state}
  end

  def handle_click(_event, state) do
    System.cmd("i3-msg", ["[class=\"^Spotify$\"] focus"])
    {:noemit, state}
  end

  ## Private functions

  defp spotify_script(), do: :code.priv_dir(:i3_status) |> Path.join("/spotify.sh")

  defp song_name() do
    case System.cmd(spotify_script(), ["song"]) do
      {name, 0} ->
        name = String.trim(name)

        case String.length(name) do
          value when value > @max_length - 3 -> "#{String.slice(name, 0..@max_length-4)}..."
          _ -> name
        end

      _ ->
        "N/A"
    end
  end

  defp playing() do
    %{
      full_text: "  #{song_name()}  "
    }
  end

  defp paused() do
    %{
      full_text: "  #{song_name()}  "
    }
  end

  defp not_started() do
    %{
      full_text: " <span fgcolor='#EA2F42'>Spotify not started</span>",
      markup: "pango"
    }
  end
end
