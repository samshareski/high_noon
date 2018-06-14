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

  def strike_noon(game) do
    %{game | high_noon: true}
    |> check_winner
  end

  def player_1_fire(%{started: true, winner: nil, player_1_status: :fine} = game) do
    case game.high_noon do
      true -> %{game | player_2_status: :shot, winner: :player_1}
      false -> %{game | player_1_status: :backfied}
    end
    |> check_winner
  end

  defp check_winner(game) do
    game
  end
end
