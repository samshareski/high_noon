defmodule HighNoon.GameServer do
  use GenServer

  alias HighNoon.Game

  @timer_median :timer.seconds(5)
  @timer_range :timer.seconds(6)

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def start_game(pid) do
    GenServer.call(pid, :start_game)
  end

  def start_fixed(pid, time) do
    GenServer.call(pid, {:start_fixed, time})
  end

  def player_1_fire(pid) do
    GenServer.call(pid, :player_1_fire)
  end

  def player_2_fire(pid) do
    GenServer.call(pid, :player_2_fire)
  end

  # Server

  def init(_args) do
    {:ok, Game.new()}
  end

  def handle_call(:start_game, from, game) do
    new_game = Game.start(game)
    Process.send_after(self(), {:high_noon, from}, random_high_noon())
    {:reply, new_game, new_game}
  end

  def handle_call({:start_fixed, time}, from, game) do
    new_game = Game.start(game)
    Process.send_after(self(), {:high_noon, from}, time)
    {:reply, new_game, new_game}
  end

  def handle_call(:player_1_fire, _from, game) do
    new_game = Game.player_1_fire(game)
    {:reply, new_game, new_game}
  end

  def handle_call(:player_2_fire, _from, game) do
    new_game = Game.player_2_fire(game)
    {:reply, new_game, new_game}
  end

  def handle_info({:high_noon, from}, game) do
    new_game = Game.strike_noon(game)
    GenServer.reply(from, {:high_noon, new_game})
    {:noreply, new_game}
  end

  def handle_info(_msg, game) do
    {:noreply, game}
  end

  # Helpers

  defp random_high_noon() do
    offset = :rand.uniform(@timer_range) - div(@timer_range, 2)
    @timer_median + offset
  end
end
