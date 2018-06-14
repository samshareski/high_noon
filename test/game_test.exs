defmodule GameTest do
  use ExUnit.Case

  alias HighNoon.Game

  test "creates a default struct" do
    assert %Game{
             started: false,
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

  test "functions won't change game before game starts" do
    game = Game.new()
    new_game = Game.player_1_fire(game)

    assert game == new_game

    game = Game.new()
    new_game = Game.player_2_fire(game)

    assert game == new_game

    game = Game.new()
    new_game = Game.strike_noon(game)

    assert game == new_game
  end

  test "high noon before any shots doesn't end game" do
    game = Game.new() |> Game.start() |> Game.strike_noon()

    assert %{winner: nil, high_noon: true} = game
  end

  test "player fire before high noon backfires" do
    game = Game.new() |> Game.start() |> Game.player_1_fire()

    assert %{player_1_status: :backfired} = game

    game = Game.new() |> Game.start() |> Game.player_2_fire()

    assert %{player_2_status: :backfired} = game
  end

  test "player fire after high noon wins" do
    game =
      Game.new()
      |> Game.start()
      |> Game.strike_noon()
      |> Game.player_1_fire()

    assert %{player_2_status: :shot, winner: :player_1}

    game =
      Game.new()
      |> Game.start()
      |> Game.strike_noon()
      |> Game.player_2_fire()

    assert %{player_1_status: :shot, winner: :player_2}
  end

  test "high noon after one backfire ends game" do
    game =
      Game.new()
      |> Game.start()
      |> Game.player_1_fire()
      |> Game.strike_noon()

    assert %{player_1_status: :backfired, winner: :player_2}

    game =
      Game.new()
      |> Game.start()
      |> Game.player_2_fire()
      |> Game.strike_noon()

    assert %{player_2_status: :backfired, winner: :player_1}
  end

  test "high noon after two backfires ends game in draw" do
    game =
      Game.new()
      |> Game.start()
      |> Game.player_1_fire()
      |> Game.player_2_fire()
      |> Game.strike_noon()

    assert %{player_1_status: :backfired, player_2_status: :backfired, winner: :draw}
  end
end
