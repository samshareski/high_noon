defmodule HighNoon.WSConn do
  defstruct name: nil, game_pid: nil, state: :registering

  alias HighNoon.WSConn

  def new do
    %WSConn{}
  end

  def set_name(conn, name) do
    %WSConn{conn | name: name}
  end

  def set_game_pid(conn, game_pid) do
    %WSConn{conn | game_pid: game_pid}
  end

  def set_state(conn, state) do
    %WSConn{conn | state: state}
  end

  def clear_game(conn) do
    %WSConn{conn | game_pid: nil}
  end
end
