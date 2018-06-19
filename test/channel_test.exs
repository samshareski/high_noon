defmodule ChannelTest do
  use ExUnit.Case

  alias HighNoon.GameChannel
  alias Helpers.WSHandlerServer

  test "handlers receive join game message" do
    {:ok, pid_1} = WSHandlerServer.start_link()
    {:ok, pid_2} = WSHandlerServer.start_link()

    {:ok, game_pid} = GameChannel.start({pid_1, pid_2})

    [last_message | _] = WSHandlerServer.messages(pid_1)
    assert {:joined_game, ^game_pid, _} = last_message

    [last_message | _] = WSHandlerServer.messages(pid_2)
    assert {:joined_game, ^game_pid, _} = last_message
  end
end
