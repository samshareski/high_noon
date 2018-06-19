defmodule ChannelTest do
  use ExUnit.Case, async: true

  alias HighNoon.GameChannel
  alias Helpers.WSHandlerServer

  test "receive join game message after starting channel" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannel.start({handler_pid, self()})

    assert_receive {:joined_game, ^game_pid, _}, :timer.seconds(3)
  end

  test "game starts after exactly 2 ready messages" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannel.start({handler_pid, self()})

    GameChannel.ready(game_pid)

    refute_receive {:started_game, _, _}, :timer.seconds(3)

    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    assert_receive {:started_game, _, _}, :timer.seconds(3)
  end

  test "high noon message received after game started" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannel.start({handler_pid, self()})

    GameChannel.ready(game_pid)
    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    # this is going to be very brittle, need to maybe change how game state is passed
    # if only just for testing purposes (there are probably other good reasons too)
    expected_game_state =
      "{\"player_2_ready\":true,\"player_1_ready\":true,\"game\":{\"winner\":null,\"started\":true,\"player_2_status\":\"fine\",\"player_1_status\":\"fine\",\"high_noon\":true}}"

    assert_receive {:game_update, _, ^expected_game_state}, :timer.seconds(15)
  end

  test "game end message received when game ends" do
    {:ok, handler_pid} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannel.start({handler_pid, self()})

    GameChannel.ready(game_pid)
    WSHandlerServer.send_ws_message(handler_pid, {:text, "Start game"})

    assert_receive {:started_game, _, _}, :timer.seconds(3)

    GameChannel.fire(game_pid)

    assert_receive {:ended_game, _, _}, :timer.seconds(15)
  end
end
