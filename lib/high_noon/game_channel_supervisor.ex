defmodule HighNoon.GameChannelSupervisor do
  use DynamicSupervisor

  alias HighNoon.GameChannelServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game({pid_1, pid_2}) do
    child_spec = %{
      id: GameChannelServer,
      start: {GameChannelServer, :start_link, [{pid_1, pid_2}]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
