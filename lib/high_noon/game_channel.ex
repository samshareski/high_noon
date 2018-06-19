defmodule HighNoon.GameChannel do
  use GenServer

  alias HighNoon.{ChannelMeta, GameServer}

  # Client

  def start({pid_1, pid_2}) do
    GenServer.start(__MODULE__, {pid_1, pid_2})
  end

  def ready(pid) do
    GenServer.cast(pid, {:ready, self()})
  end

  def fire(pid) do
    GenServer.cast(pid, {:fire, self()})
  end

  # Server

  def init({pid_1, pid_2}) do
    {:ok, game_pid} = GameServer.start_link()
    game_state = GameServer.get_game_state(game_pid)

    state = ChannelMeta.new(pid_1, pid_2, game_pid, game_state)

    broadcast_state(state, :joined_game)

    {:ok, state}
  end

  def handle_cast({:ready, from_pid}, state) do
    new_state =
      cond do
        from_pid == state.player_1_pid -> ChannelMeta.ready_player_1(state)
        from_pid == state.player_2_pid -> ChannelMeta.ready_player_2(state)
      end

    broadcast_state(new_state)

    if new_state.player_1_ready == true and new_state.player_2_ready == true do
      Process.send_after(self(), :start, :timer.seconds(2))
    end

    {:noreply, new_state}
  end

  def handle_cast({:fire, from_pid}, state) do
    new_game_state =
      cond do
        from_pid == state.player_1_pid -> GameServer.player_1_fire(state.game_pid)
        from_pid == state.player_2_pid -> GameServer.player_2_fire(state.game_pid)
      end

    new_state = %{state | game: new_game_state}

    type =
      if new_game_state.winner != nil do
        :ended
      else
        :game_update
      end

    broadcast_state(new_state, type)

    {:noreply, new_state}
  end

  def handle_info(:start, state) do
    new_game_state = GameServer.start_game(state.game_pid)
    new_state = %{state | game: new_game_state}

    broadcast_state(new_state, :started_game)

    {:noreply, new_state}
  end

  def handle_info({_, {:high_noon, new_game_state}}, state) do
    new_state = %{state | game: new_game_state}

    type =
      if new_game_state.winner != nil do
        :ended_game
      else
        :game_update
      end

    broadcast_state(new_state, type)

    {:noreply, new_state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp broadcast_state(state, type \\ :game_update) do
    Enum.map(
      [state.player_1_pid, state.player_2_pid],
      &send(&1, {type, self(), Poison.encode!(state)})
    )
  end
end
