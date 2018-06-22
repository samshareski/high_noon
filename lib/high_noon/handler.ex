defmodule HighNoon.Handler do
  @behaviour :cowboy_websocket

  require Logger

  alias HighNoon.{GameChannelServer, Matchmaker, WSConn, ConnectedPlayers}
  import Poison, only: [encode!: 1]

  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :timer.minutes(5)}}
  end

  def websocket_init(_state) do
    {:ok, %WSConn{}}
  end

  def websocket_handle({:text, "name:" <> name}, %{state: :registering} = conn) do
    new_conn = %{conn | name: name, state: :searching}

    {:ok, _} = Registry.register(ConnectedPlayers, name, :name)

    Matchmaker.register_and_add(self())
    {:reply, {:text, encode!(%{type: :searching})}, new_conn}
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
    search_for_new_game(conn)
  end

  def websocket_handle(_frame, %{state: :disconnected} = conn) do
    search_for_new_game(conn)
  end

  def websocket_handle(_frame, conn) do
    {:reply, {:text, "Unrecognized message"}, conn}
  end

  def websocket_info(:joining_game, conn) do
    new_conn = %{conn | state: :joining_game}
    {:reply, {:text, encode!(%{type: :joining_game})}, new_conn}
  end

  def websocket_info({:joined_game, game_pid, game_roster, game_readiness, game_state}, conn) do
    Process.monitor(game_pid)

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

  def websocket_info({:DOWN, _ref, :process, _game_pid, :normal}, conn) do
    {:ok, conn}
  end

  def websocket_info({:DOWN, _ref, :process, _game_pid, :player_disconnect}, conn) do
    new_conn = %{conn | game_pid: nil, state: :disconnected}
    {:reply, {:text, encode!(%{type: :opponent_left})}, new_conn}
  end

  def websocket_info({:DOWN, _ref, :process, _game_pid, _reason}, conn) do
    new_conn = %{conn | game_pid: nil, state: :disconnected}
    {:reply, {:text, encode!(%{type: :disconnected})}, new_conn}
  end

  def websocket_info(info, conn) do
    Logger.warn("Unrecognized message" <> inspect(info))
    {:ok, conn}
  end

  defp search_for_new_game(conn) do
    new_conn = %{conn | game_pid: nil, state: :searching}

    Matchmaker.add_to_pool(self())
    {:reply, {:text, encode!(%{type: :searching})}, new_conn}
  end

  defp game_joined_response(game_roster, game_readiness, game_state) do
    encode!(%{
      type: :joined_game,
      game_roster: game_roster,
      game_readiness: game_readiness,
      game_state: game_state
    })
  end

  defp game_status_response(game_readiness, game_state) do
    encode!(%{
      type: :game_update,
      game_readiness: game_readiness,
      game_state: game_state
    })
  end
end
