defmodule Pushy do
  use Application

  require Logger

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Pushy.Router,
        options: [port: 4000],
        protocol_options: [idle_timeout: :infinity]
      ),
      {Phoenix.PubSub, name: Pushy.PubSub}
    ]

    opts = [strategy: :one_for_one, name: Pushy.Supervisor]
    result = Supervisor.start_link(children, opts)

    Logger.info("Server started at http://localhost:4000")

    result
  end
end
