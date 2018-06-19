defmodule HighNoon.ChannelMeta do
  @enforce_keys [:player_1_pid, :player_2_pid, :game_meta, :game_state]

  defstruct player_1_pid: nil,
            player_2_pid: nil,
            game_meta: nil,
            game_state: nil

  alias HighNoon.ChannelMeta

  def new(pid_1, pid_2, game_meta, game_state) do
    %ChannelMeta{
      player_1_pid: pid_1,
      player_2_pid: pid_2,
      game_meta: game_meta,
      game_state: game_state
    }
  end
end
