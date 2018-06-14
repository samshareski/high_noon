defmodule HighNoon.Game do
  defstruct started: false,
            high_noon: false,
            player_1_status: :fine,
            player_2_status: :fine,
            winner: nil

  alias HighNoon.Game

  def new() do
    struct(Game)
  end

  def start(game) do
    %{game | started: true}
  end

  def strike_noon(%{started: true} = game) do
    %{game | high_noon: true}
    |> check_winner
  end

  def strike_noon(game) do
    game
  end

  def player_1_fire(%{started: true, winner: nil, player_1_status: :fine} = game) do
    case game.high_noon do
      true -> %{game | player_2_status: :shot}
      false -> %{game | player_1_status: :backfired}
    end
    |> check_winner
  end

  def player_1_fire(game) do
    game
  end

  def player_2_fire(%{started: true, winner: nil, player_2_status: :fine} = game) do
    case game.high_noon do
      true -> %{game | player_1_status: :shot}
      false -> %{game | player_2_status: :backfired}
    end
    |> check_winner
  end

  def player_2_fire(game) do
    game
  end

  defp check_winner(%{high_noon: true} = game) do
    cond do
      game.player_1_status == :fine and game.player_2_status != :fine ->
        %{game | winner: :player_1}

      game.player_2_status == :fine and game.player_2_status != :fine ->
        %{game | winner: :player_2}

      game.player_2_status != :fine and game.player_2_status != :fine ->
        %{game | winner: :draw}

      true ->
        game
    end
  end

  defp check_winner(game) do
    game
  end
end
