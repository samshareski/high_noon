defmodule ChannelTest do
  use ExUnit.Case, async: true

  alias HighNoon.GameChannelServer
  alias Helpers.WSHandlerServer

  test "receive join game message after starting channel" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannelServer.start({handler_pid, self()})

    assert_receive {:joined_game, ^game_pid, _, _, _}, :timer.seconds(3)
  end

  test "game starts after exactly 2 ready messages" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannelServer.start({handler_pid, self()})

    GameChannelServer.ready(game_pid)

    refute_receive {:started_game, _, _}, :timer.seconds(3)

    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    assert_receive {:started_game, _, _}, :timer.seconds(3)
  end

  test "high noon message received after game started" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannelServer.start({handler_pid, self()})

    GameChannelServer.ready(game_pid)
    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    assert_receive {:game_update, _, %{high_noon: true}}, :timer.seconds(15)
  end

  test "game end message received when game ends" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannelServer.start({handler_pid, self()})

    GameChannelServer.ready(game_pid)
    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    assert_receive {:started_game, _, _}, :timer.seconds(3)

    GameChannelServer.fire(game_pid)

    assert_receive {:ended_game, _, _}, :timer.seconds(15)
  end
end
