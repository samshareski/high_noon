defmodule HighNoonTest do
  use ExUnit.Case
  doctest HighNoon

  test "greets the world" do
    assert HighNoon.hello() == :world
  end
end
