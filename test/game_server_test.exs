defmodule GameServerTest do
  use ExUnit.Case

  alias HighNoon.GameServer

  test "spawning a game server process" do
    assert {:ok, _pid} = GameServer.start_link()
  end
end
