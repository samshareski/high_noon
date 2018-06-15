defmodule HighNoon.WSConn do
  defstruct name: nil, game: nil

  alias HighNoon.WSConn

  def new do
    %WSConn{}
  end

  def set_name(ws_conn, name) do
    %WSConn{ws_conn | name: name}
  end

  def set_game(ws_conn, game) do
    %WSConn{ws_conn | game: game}
  end

  def clear_game(ws_conn) do
    %WSConn{ws_conn | game: nil}
  end
end
