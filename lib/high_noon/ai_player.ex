defmodule HighNoon.AIPlayer do
  use GenServer

  alias HighNoon.{GameChannelServer, ConnectedPlayers}

  @timeout :timer.minutes(2)
  @min_reaction_time 350
  @reaction_time_range 250

  # Client

  def start do
    GenServer.start(__MODULE__, :ok)
  end

  # Server

  def init(:ok) do
    {:ok, _} = Registry.register(ConnectedPlayers, "Mr. Robot", :name)
    {:ok, %{}, @timeout}
  end

  def handle_info({:joined_game, game_pid, _, _, _}, state) do
    new_state = Map.put(state, :game_pid, game_pid)

    GameChannelServer.ready(game_pid)

    {:noreply, new_state, @timeout}
  end

  def handle_info({:game_update, _, %{high_noon: true}}, state) do
    Process.send_after(self(), :fire, @min_reaction_time + :rand.uniform(@reaction_time_range))
    {:noreply, state, @timeout}
  end

  def handle_info({:ended_game, _, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info(:fire, state) do
    GameChannelServer.fire(state.game_pid)
    {:noreply, state, @timeout}
  end

  def handle_info(_msg, state) do
    {:noreply, state, @timeout}
  end
end
