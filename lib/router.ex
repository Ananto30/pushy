defmodule Pushy.Router do
  import Plug.Conn

  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(:match)
  plug(Plug.Logger)
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

  post "/publish/:channel" do
    case parse_param(conn, "data")
         |> make_event()
         |> send_event(channel) do
      :ok ->
        conn
        |> send_resp(200, "")

      {:error, reason} ->
        conn
        |> send_resp(500, err_json(reason))
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
    Logger.error(beautify_stack(stack))

    case reason do
      %Plug.Parsers.UnsupportedMediaTypeError{} ->
        send_resp(conn, 415, err_json("Unsupported media type"))

      %Plug.Parsers.ParseError{} ->
        send_resp(conn, 400, err_json("Invalid JSON"))
    end
  end

  defp parse_param(conn, param) do
    case Map.get(conn.params, param) do
      nil ->
        conn
        |> send_resp(400, err_json("Missing parameter: #{param}"))

      value ->
        value
    end
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

  defp make_event(data) do
    data = Jason.encode!(data)
    uuid = UUID.uuid4()
    "event: message\ndata: #{data}\nid: #{uuid}\nretry: 100\n\n"
  end

  defp send_event(event, channel) do
    Phoenix.PubSub.broadcast(Pushy.PubSub, channel, {:sse, event})
  end

  defp err_json(reason) do
    Jason.encode!(%{message: reason})
  end

  defp beautify_stack(stack) do
    stack
    |> Exception.format_stacktrace()
  end
end
