defmodule HighNoon.Handler do
  @behaviour :cowboy_websocket

  require Logger

  alias HighNoon.{GameChannelServer, Matchmaker, WSConn, ConnectedPlayers}

  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :timer.minutes(5)}}
  end

  def websocket_init(_state) do
    {:ok, %WSConn{}}
  end

  def websocket_handle({:text, "name:" <> name}, %{state: :registering} = conn) do
    new_conn = %{conn | name: name, state: :searching}

    {:ok, _} = Registry.register(ConnectedPlayers, name, :name)

    Matchmaker.add_to_pool(self())
    {:reply, {:text, "Welcome " <> name}, new_conn}
  end

  def websocket_handle(_frame, %{state: :registering} = conn) do
    {:reply, {:text, "Please send you name in the form \"name:<<your name>>\""}, conn}
  end

  def websocket_handle(_frame, %{state: :joined_game} = conn) do
    GameChannelServer.ready(conn.game_pid)
    new_conn = %{conn | state: :ready}
    {:ok, new_conn}
  end

  def websocket_handle(_frame, %{state: :game_started} = conn) do
    GameChannelServer.fire(conn.game_pid)
    {:ok, conn}
  end

  def websocket_handle(_frame, %{state: :game_ended} = conn) do
    new_conn = %{conn | game_pid: nil, state: :searching}

    Matchmaker.add_to_pool(self())
    {:reply, {:text, "Searching for a new game"}, new_conn}
  end

  def websocket_handle(frame, conn) do
    Logger.info("Unrecognized message: " <> inspect(frame))
    {:reply, {:text, "Unrecognized message"}, conn}
  end

  def websocket_info(:joining_game, conn) do
    new_conn = %{conn | state: :joining_game}
    {:reply, {:text, "Joining game"}, new_conn}
  end

  def websocket_info({:joined_game, game_pid, game_roster, game_readiness, game_state}, conn) do
    new_conn = %{conn | game_pid: game_pid, state: :joined_game}

    {:reply, {:text, game_joined_response(game_roster, game_readiness, game_state)}, new_conn}
  end

  def websocket_info({:started_game, game_readiness, game_state}, conn) do
    new_conn = %{conn | state: :game_started}
    {:reply, {:text, game_status_response(game_readiness, game_state)}, new_conn}
  end

  def websocket_info({:ended_game, game_readiness, game_state}, conn) do
    new_conn = %{conn | state: :game_ended}
    {:reply, {:text, game_status_response(game_readiness, game_state)}, new_conn}
  end

  def websocket_info({:game_update, game_readiness, game_state}, conn) do
    {:reply, {:text, game_status_response(game_readiness, game_state)}, conn}
  end

  def websocket_info(_info, conn) do
    {:ok, conn}
  end

  defp game_joined_response(game_roster, game_readiness, game_state) do
    Poison.encode!(%{
      game_roster: game_roster,
      game_readiness: game_readiness,
      game_state: game_state
    })
  end

  defp game_status_response(game_readiness, game_state) do
    Poison.encode!(%{
      game_readiness: game_readiness,
      game_state: game_state
    })
  end
end
