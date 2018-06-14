defmodule GameTest do
  use ExUnit.Case

  alias HighNoon.Game

  test "creates a default struct" do
    assert %Game{
             started: false,
             ended: false,
             high_noon: false,
             player_1_status: :fine,
             player_2_status: :fine,
             winner: nil
           } = Game.new()
  end

  test "starts a game" do
    game = Game.new() |> Game.start()

    assert %{started: true} = game
  end
end
