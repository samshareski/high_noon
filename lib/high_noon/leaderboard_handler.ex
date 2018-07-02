defmodule HighNoon.LeaderboardHandler do
  @behaviour :cowboy_websocket

  require Logger

  alias HighNoon.{Leaderboard}
  import Poison, only: [encode!: 1]

  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :timer.minutes(60)}}
  end

  def websocket_init(_state) do
    Leaderboard.listen(self())
    {:ok, []}
  end

  def websocket_handle(_frame, conn) do
    {:reply, {:text, "We don't respond to messages, you just listen"}, conn}
  end

  def websocket_info({:leaderboard_update, leaderboard}, conn) do
    {:reply, {:text, encode!(leaderboard)}, conn}
  end

  def websocket_info(info, conn) do
    Logger.warn("Unrecognized message" <> inspect(info))
    {:ok, conn}
  end
end
