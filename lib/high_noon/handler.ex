defmodule HighNoon.Handler do
  @behaviour :cowboy_websocket

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_handle(frame, state) do
    {:reply, frame, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end
end
