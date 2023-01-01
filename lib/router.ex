defmodule Pushy.Router do
  import Plug.Conn
  use Plug.Router
  require Logger

  plug(:match)
  plug(Pushy.Auth)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  post "/sse" do
    channels = parse_param(conn, "channels")

    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

    Enum.each(channels, fn channel ->
      Phoenix.PubSub.subscribe(Pushy.PubSub, channel)
    end)

    receiver_loop(conn)
  end

  post "/publish" do
    channel = parse_param(conn, "channel")
    data = parse_param(conn, "data")
    event = make_event(data)

    case Phoenix.PubSub.broadcast(Pushy.PubSub, channel, {:sse, event}) do
      :ok ->
        conn
        |> send_resp(200, "OK")

      {:error, reason} ->
        conn
        |> send_resp(500, "Error: #{reason}")
    end
  end

  defp make_event(data) do
    data = Jason.encode!(data)
    uuid = UUID.uuid4()
    "event: message\ndata: #{data}\nid: #{uuid}\nretry: 6000\n\n"
  end

  defp receiver_loop(conn) do
    receive do
      {:sse, data} ->
        chunk(conn, data)
        receiver_loop(conn)

      _ ->
        receiver_loop(conn)
    end
  end

  defp parse_param(conn, param) do
    case Map.get(conn.params, param) do
      nil ->
        conn
        |> send_resp(400, "Missing parameter: #{param}")

      value ->
        value
    end
  end
end
