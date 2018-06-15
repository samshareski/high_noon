defmodule HighNoon do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      HighNoon.Matchmaker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HighNoon.Supervisor]
    Supervisor.start_link(children, opts)

    start_ws_listener()
  end

  defp start_ws_listener do
    dispatch =
      :cowboy_router.compile([
        {:_, [{"/", HighNoon.Handler, []}]}
      ])

    {:ok, _} = :cowboy.start_clear(:ws_api, [{:port, 8080}], %{env: %{dispatch: dispatch}})
  end
end
