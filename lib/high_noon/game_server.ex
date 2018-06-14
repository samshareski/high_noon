defmodule HighNoon.GameServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end
end
