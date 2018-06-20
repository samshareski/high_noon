defmodule HighNoon.Matchmaker do
  use GenServer

  alias HighNoon.GameChannelServer

  # Client

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_to_pool(pid) do
    GenServer.cast(__MODULE__, {:add_to_pool, pid})
  end

  # Server

  def init(_args) do
    {:ok, nil}
  end

  def handle_cast({:add_to_pool, pid}, state) do
    new_state =
      case state do
        nil ->
          pid

        waiting_pid ->
          Enum.map([pid, waiting_pid], &send(&1, :joining_game))
          GameChannelServer.start({pid, waiting_pid})
          nil
      end

    {:noreply, new_state}
  end
end
