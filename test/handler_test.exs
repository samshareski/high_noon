defmodule HandlerTest do
  use ExUnit.Case, async: true

  alias HighNoon.{Handler, WSConn}

  test "initializes with empty state" do
    {:ok, state} = Handler.websocket_init([])
    assert %WSConn{} = state
  end

  test "updates state with name" do
    {:ok, state} = Handler.websocket_init([])

    {:reply, {:text, reply}, updated_state} = Handler.websocket_handle({:text, "name:Sam"}, state)

    assert Poison.encode!(%{type: :searching}) == reply
    assert %{name: "Sam"} = updated_state
  end
end
