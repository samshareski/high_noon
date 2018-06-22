defmodule HighNoon.Matchmaker do
  use GenServer

  alias HighNoon.GameChannelSupervisor

  require Logger

  @interval :timer.seconds(1)

  # Client

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def register_and_add(pid) do
    GenServer.cast(__MODULE__, {:register_and_add, pid})
  end

  def add_to_pool(pid) do
    GenServer.cast(__MODULE__, {:add_to_pool, pid})
  end

  # Server

  def init(_args) do
    Process.send_after(self(), :matchmake, @interval)
    {:ok, []}
  end

  def handle_cast({:register_and_add, pid}, state) do
    Process.monitor(pid)
    {:noreply, [pid | state]}
  end

  def handle_cast({:add_to_pool, pid}, state) do
    {:noreply, [pid | state]}
  end

  def handle_info(:matchmake, state) do
    new_state =
      state
      |> Enum.reverse()
      |> Enum.chunk_every(2)
      |> Enum.reduce([], &matchmake_reducer/2)

    Process.send_after(self(), :matchmake, @interval)
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, player_pid, _reason}, state) do
    new_state = List.delete(state, player_pid)
    {:noreply, new_state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unrecognized message: " <> inspect(msg))
    {:noreply, state}
  end

  defp matchmake_reducer([player_1_pid, player_2_pid], acc) do
    Enum.map([player_1_pid, player_2_pid], &send(&1, :joining_game))
    GameChannelSupervisor.start_game({player_1_pid, player_2_pid})
    acc
  end

  defp matchmake_reducer([remaining_player], acc) do
    [remaining_player | acc]
  end
end
