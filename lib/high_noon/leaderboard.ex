defmodule HighNoon.Leaderboard do
  use GenServer

  # Client

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def record_win(winning_pid) do
    GenServer.cast(__MODULE__, {:record_win, winning_pid})
  end

  def listen(listener_pid) do
    GenServer.cast(__MODULE__, {:listen, listener_pid})
  end

  # Server

  def init(:ok) do
    {:ok, %{leaderboard: [], listeners: []}}
  end

  def handle_cast({:record_win, winning_pid}, state) do
    player_name =
      case player_name(winning_pid) do
        nil -> "Mr. Robot"
        name -> name
      end

    new_state =
      case player_name do
        "Mr. Robot" ->
          state

        _ ->
          new_entry =
            case List.keyfind(state.leaderboard, winning_pid, 0) do
              nil -> {winning_pid, player_name, 1}
              {^winning_pid, name, wins} -> {winning_pid, name, wins + 1}
            end

          new_leaderboard = List.keystore(state.leaderboard, winning_pid, 0, new_entry)

          new_state = %{state | leaderboard: new_leaderboard}

          notify_listeners(new_state)

          new_state
      end

    {:noreply, new_state}
  end

  def handle_cast({:listen, listener_pid}, state) do
    Process.monitor(listener_pid)
    new_listeners = [listener_pid | state.listeners]
    {:noreply, %{state | listeners: new_listeners}}
  end

  def handle_info({:DOWN, _ref, :process, listener_pid, _reason}, state) do
    new_listeners = List.delete(state.listeners, listener_pid)
    {:noreply, %{state | listeners: new_listeners}}
  end

  defp notify_listeners(state) do
    Enum.map(
      state.listeners,
      &send(&1, {:leaderboard_update, leaderboard_top_ten(state.leaderboard)})
    )
  end

  defp leaderboard_top_ten(leaderboard) do
    leaderboard
    |> List.keysort(2)
    |> Enum.reverse()
    |> Enum.take(10)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn [_pid | rest] -> rest end)
  end

  defp player_name(player_pid) do
    Registry.keys(HighNoon.ConnectedPlayers, player_pid) |> List.first()
  end
end
