defmodule HighNoon do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :duplicate, name: HighNoon.ConnectedPlayers},
      HighNoon.Matchmaker,
      {DynamicSupervisor, name: HighNoon.GameChannelSupervisor, strategy: :one_for_one}
    ]

    start_ws_listener()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HighNoon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_ws_listener do
    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {"/", :cowboy_static, {:priv_file, :high_noon, "static/index.html"}},
           {"/static/[...]", :cowboy_static, {:priv_dir, :high_noon, "static"}},
           {"/ws", HighNoon.Handler, []}
         ]}
      ])

    port_string = Application.get_env(:high_noon, :port, "8080")
    Logger.info("Port env variable was: #{port_string}")
    {port, _} = Integer.parse(port_string)
    # {port, _} = Application.get_env(:high_noon, :port, "8080") |> Integer.parse()

    {:ok, _} =
      :cowboy.start_clear(:ws_api, [{:port, port}], %{
        env: %{dispatch: dispatch}
      })

    Logger.info("Now listening on port: #{port}")
  end
end
