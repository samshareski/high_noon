defmodule HighNoon.GameChannel do
  @enforce_keys [:player_1_pid, :player_2_pid, :game_server_pid, :game_state]

  defstruct player_1_pid: nil,
            player_2_pid: nil,
            player_1_ready: false,
            player_2_ready: false,
            game_server_pid: nil,
            game_state: nil

  alias HighNoon.GameChannel

  def new(pid_1, pid_2, game_server_pid, game_state) do
    %GameChannel{
      player_1_pid: pid_1,
      player_2_pid: pid_2,
      game_server_pid: game_server_pid,
      game_state: game_state
    }
  end
end
