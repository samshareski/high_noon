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
      HighNoon.Leaderboard,
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
           {"/", :cowboy_static, {:priv_file, :high_noon, "game/index.html"}},
           {"/leaderboard/", :cowboy_static, {:priv_file, :high_noon, "leaderboard/index.html"}},
           {"/leaderboard/ws", HighNoon.LeaderboardHandler, []},
           {"/ws", HighNoon.Handler, []},
           {"/[...]", :cowboy_static, {:priv_dir, :high_noon, "game"}}
         ]}
      ])

    {port, _} = (System.get_env("PORT") || "8080") |> Integer.parse()

    {:ok, _} =
      :cowboy.start_clear(:ws_api, [{:port, port}], %{
        env: %{dispatch: dispatch}
      })

    Logger.info("Now listening on port: #{port}")
  end
end
