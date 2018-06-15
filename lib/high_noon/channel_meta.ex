defmodule HighNoon.ChannelMeta do
  @enforce_keys [:player_1_pid, :player_2_pid, :game_pid, :game]
  @derive {Poison.Encoder, except: [:player_1_pid, :player_2_pid, :game_pid]}

  defstruct player_1_pid: nil,
            player_2_pid: nil,
            player_1_ready: false,
            player_2_ready: false,
            game_pid: nil,
            game: nil

  alias HighNoon.ChannelMeta

  def new(pid_1, pid_2, game_pid, game) do
    %ChannelMeta{player_1_pid: pid_1, player_2_pid: pid_2, game_pid: game_pid, game: game}
  end

  def ready_player_1(meta) do
    %{meta | player_1_ready: true}
  end

  def ready_player_2(meta) do
    %{meta | player_2_ready: true}
  end
end
