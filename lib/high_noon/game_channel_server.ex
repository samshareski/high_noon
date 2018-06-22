defmodule HighNoon.GameChannelServer do
  use GenServer

  require Logger

  alias HighNoon.{GameChannel, GameServer, ConnectedPlayers}

  # Client

  def start_link({pid_1, pid_2}) do
    GenServer.start_link(__MODULE__, {pid_1, pid_2})
  end

  def ready(pid) do
    GenServer.cast(pid, {:ready, self()})
  end

  def fire(pid) do
    GenServer.cast(pid, {:fire, self()})
  end

  # Server

  def init({player_1_pid, player_2_pid}) do
    {:ok, game_server_pid} = GameServer.start_link()
    game_state = GameServer.get_game_state(game_server_pid)

    Process.monitor(player_1_pid)
    Process.monitor(player_2_pid)

    state = GameChannel.new(player_1_pid, player_2_pid, game_server_pid, game_state)

    broadcast_initial_state(state)

    {:ok, state}
  end

  def handle_cast({:ready, from_pid}, state) do
    new_state =
      case state do
        %{player_1_pid: ^from_pid} -> %{state | player_1_ready: true}
        %{player_2_pid: ^from_pid} -> %{state | player_2_ready: true}
      end

    broadcast_state(new_state)

    with %{player_1_ready: true, player_2_ready: true} <- new_state,
         do: Process.send_after(self(), :start, :timer.seconds(2))

    {:noreply, new_state}
  end

  def handle_cast({:fire, from_pid}, state) do
    new_game_state =
      case state do
        %{player_1_pid: ^from_pid} -> GameServer.player_1_fire(state.game_server_pid)
        %{player_2_pid: ^from_pid} -> GameServer.player_2_fire(state.game_server_pid)
      end

    new_state = %{state | game_state: new_game_state}

    check_winner_and_broadcast(new_state)
  end

  def handle_info(:start, state) do
    new_game_state = GameServer.start_game(state.game_server_pid)
    new_state = %{state | game_state: new_game_state}

    broadcast_state(new_state, :started_game)

    {:noreply, new_state}
  end

  def handle_info({_, {:high_noon, new_game_state}}, state) do
    new_state = %{state | game_state: new_game_state}

    check_winner_and_broadcast(new_state)
  end

  def handle_info({:DOWN, _ref, :process, _player_pid, _reason}, state) do
    {:stop, :player_disconnect, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unrecognized msg" <> inspect(msg))
    {:noreply, state}
  end

  defp broadcast_state(state, type \\ :game_update) do
    Enum.map(
      [state.player_1_pid, state.player_2_pid],
      &send(&1, {type, game_readiness_map(state), state.game_state})
    )
  end

  defp broadcast_initial_state(state) do
    game_roster = game_roster(state)
    player_1_roster = Map.put(game_roster, :assignment, :player_1)
    player_2_roster = Map.put(game_roster, :assignment, :player_2)

    send(state.player_1_pid, {
      :joined_game,
      self(),
      player_1_roster,
      game_readiness_map(state),
      state.game_state
    })

    send(state.player_2_pid, {
      :joined_game,
      self(),
      player_2_roster,
      game_readiness_map(state),
      state.game_state
    })
  end

  defp game_roster(state) do
    %{
      player_1: player_name(state.player_1_pid),
      player_2: player_name(state.player_2_pid)
    }
  end

  defp player_name(player_pid) do
    Registry.keys(ConnectedPlayers, player_pid) |> List.first()
  end

  defp game_readiness_map(state) do
    Map.from_struct(state)
    |> Map.take([:player_1_ready, :player_2_ready])
  end

  defp check_winner_and_broadcast(state) do
    case state.game_state.winner do
      nil ->
        broadcast_state(state, :game_update)
        {:noreply, state}

      _any_winner ->
        broadcast_state(state, :ended_game)
        {:stop, :normal, state}
    end
  end
end
