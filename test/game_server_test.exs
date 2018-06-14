defmodule GameServerTest do
  use ExUnit.Case

  alias HighNoon.{GameServer, Game}

  test "spawning a game server process" do
    assert {:ok, _pid} = GameServer.start_link()
  end

  test "start a game in the game server" do
    assert {:ok, pid} = GameServer.start_link()

    game = GameServer.start_game(pid)

    assert %Game{started: true} = game
  end

  test "recieve high noon message after starting game" do
    assert {:ok, pid} = GameServer.start_link()

    GameServer.start_fixed(pid, 100)

    assert_receive {_, {:high_noon, %{started: true, high_noon: true}}}, :timer.seconds(2)
  end

  test "player fires before noon and loses" do
    assert {:ok, pid} = GameServer.start_link()

    GameServer.start_fixed(pid, 100)
    assert %{player_1_status: :backfired} = GameServer.player_1_fire(pid)

    assert_receive {_, {:high_noon, %{winner: :player_2}}}, :timer.seconds(2)
  end

  test "player fires after noon and wins" do
    assert {:ok, pid} = GameServer.start_link()

    GameServer.start_fixed(pid, 100)

    assert_receive {_, {:high_noon, %{winner: nil}}}, :timer.seconds(2)

    assert %{winner: :player_1} = GameServer.player_1_fire(pid)
  end

  test "both players fire before noon and draw" do
    assert {:ok, pid} = GameServer.start_link()

    GameServer.start_fixed(pid, 100)

    assert %{player_1_status: :backfired} = GameServer.player_1_fire(pid)
    assert %{player_2_status: :backfired} = GameServer.player_2_fire(pid)

    assert_receive {_, {:high_noon, %{winner: :draw}}}, :timer.seconds(2)
  end
end
