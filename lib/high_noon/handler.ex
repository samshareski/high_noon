defmodule HighNoon.Handler do
  @behaviour :cowboy_websocket

  require Logger

  alias HighNoon.{GameChannel, Matchmaker, WSConn}

  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :timer.minutes(5)}}
  end

  def websocket_init(_state) do
    {:ok, WSConn.new()}
  end

  def websocket_handle({:text, "name:" <> name}, %{state: :registering} = conn) do
    new_conn =
      conn
      |> WSConn.set_name(name)
      |> WSConn.set_state(:searching)

    Matchmaker.add_to_pool(self())
    {:reply, {:text, "Welcome " <> name}, new_conn}
  end

  def websocket_handle(_frame, %{state: :registering} = conn) do
    {:reply, {:text, "Please send you name in the form \"name:<<your name>>\""}, conn}
  end

  def websocket_handle(_frame, %{state: :joined_game} = conn) do
    GameChannel.ready(conn.game_pid)
    new_conn = WSConn.set_state(conn, :ready)
    {:ok, new_conn}
  end

  def websocket_handle(_frame, %{state: :game_started} = conn) do
    GameChannel.fire(conn.game_pid)
    {:ok, conn}
  end

  def websocket_handle(_frame, %{state: :game_ended} = conn) do
    new_conn =
      conn
      |> WSConn.clear_game()
      |> WSConn.set_state(:searching)

    Matchmaker.add_to_pool(self())
    {:reply, {:text, "Searching for a new game"}, new_conn}
  end

  def websocket_handle(frame, conn) do
    Logger.info("Unrecognized message: " <> inspect(frame))
    {:reply, {:text, "Unrecognized message"}, conn}
  end

  def websocket_info(:joining_game, conn) do
    new_conn = WSConn.set_state(conn, :joining_game)
    {:reply, {:text, "Joining game"}, new_conn}
  end

  def websocket_info({:joined_game, game_pid, game_state}, conn) do
    new_conn =
      conn
      |> WSConn.set_game_pid(game_pid)
      |> WSConn.set_state(:joined_game)

    {:reply, {:text, game_state}, new_conn}
  end

  def websocket_info({:started_game, _game_pid, game_state}, conn) do
    new_conn = WSConn.set_state(conn, :game_started)
    {:reply, {:text, game_state}, new_conn}
  end

  def websocket_info({:ended_game, _game_pid, game_state}, conn) do
    new_conn = WSConn.set_state(conn, :game_ended)
    {:reply, {:text, game_state}, new_conn}
  end

  def websocket_info({:game_update, _game_pid, game_state}, conn) do
    {:reply, {:text, game_state}, conn}
  end

  def websocket_info(_info, conn) do
    {:ok, conn}
  end
end
