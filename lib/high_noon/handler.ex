defmodule HighNoon.Handler do
  @behaviour :cowboy_websocket

  require Logger

  alias HighNoon.{Matchmaker, WSConn}

  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :timer.minutes(5)}}
  end

  def websocket_init(_state) do
    {:ok, WSConn.new()}
  end

  def websocket_handle({:text, "name:" <> name}, %{name: nil} = state) do
    new_state = WSConn.set_name(state, name)
    Matchmaker.add_to_pool(self())
    {:reply, {:text, "Welcome " <> name}, new_state}
  end

  def websocket_handle(_frame, %{name: nil} = state) do
    {:reply, {:text, "Please send you name in the form \"name:<<your name>>\""}, state}
  end

  def websocket_handle(frame, state) do
    Logger.info("Unrecognized message: " <> inspect(frame))
    {:reply, {:text, "Unrecognized message"}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end
end
