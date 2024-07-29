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
    conn
    |> handle_sse_request()
  end

  post "/publish/:channel" do
    conn
    |> handle_publish_request(channel)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
    Logger.error(beautify_stack(stack))

    conn
    |> handle_error_response(reason)
  end

  defp handle_error_response(conn, %Plug.Parsers.UnsupportedMediaTypeError{}) do
    send_resp(conn, 415, err_json("Unsupported media type"))
  end

  defp handle_error_response(conn, %Plug.Parsers.ParseError{}) do
    send_resp(conn, 400, err_json("Invalid JSON"))
  end

  defp handle_error_response(conn, _reason) do
    send_resp(conn, 500, err_json("Internal server error"))
  end

  defp parse_param(conn, param) do
    params = conn.params || %{}

    case Map.get(params, param) do
      nil -> {:error, "Missing parameter: #{param}"}
      "" -> {:error, "Empty parameter: #{param}"}
      value -> {:ok, value}
    end
  end

  defp handle_sse_request(conn) do
    conn
    |> parse_channels()
    |> case do
      {:ok, channels} ->
        conn
        |> prepare_sse_response()
        |> subscribe_and_loop(channels)

      {:error, message} ->
        send_resp(conn, 400, err_json(message))
    end
  end

  defp parse_channels(conn) do
    case parse_param(conn, "channels") do
      {:ok, channels} when is_list(channels) -> {:ok, channels}
      {:ok, channel} -> {:ok, [channel]}
      {:error, message} -> {:error, message}
    end
  end

  defp prepare_sse_response(conn) do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_chunked(200)
  end

  defp subscribe_and_loop(conn, channels) do
    conn
    |> subscribe_to_channels(channels)
    |> receiver_loop()
  end

  defp subscribe_to_channels(conn, channels) do
    # Subscribe to each channel
    # This will allow the connection to receive messages
    # from the subscribed channels
    # The connection will be kept alive until the client disconnects
    # or the server closes the connection
    Enum.each(channels, fn channel ->
      Phoenix.PubSub.subscribe(Pushy.PubSub, channel)
    end)

    Logger.info("Subscribed to channels: #{inspect(channels)}")

    conn
  end

  defp receiver_loop(conn) do
    # This is a tail-recursive function
    # that will keep the connection open
    # until the client disconnects
    # or the server closes the connection
    receive do
      {:sse, data} ->
        chunk(conn, data)
        receiver_loop(conn)

      _ ->
        receiver_loop(conn)
    end
  end

  defp handle_publish_request(conn, channel) do
    case parse_param(conn, "data") do
      {:ok, data} -> handle_publish(conn, channel, data)
      {:error, message} -> send_resp(conn, 400, err_json(message))
    end
  end

  defp handle_publish(conn, channel, data) do
    data
    |> add_timestamp()
    |> make_event()
    |> send_event(channel)
    |> handle_event_response(conn)
  end

  defp add_timestamp(data) do
    Map.put(data, "timestamp", :os.system_time(:seconds))
  end

  defp handle_event_response(:ok, conn) do
    send_resp(conn, 200, "")
  end

  defp handle_event_response({:error, reason}, conn) do
    send_resp(conn, 500, err_json(reason))
  end

  defp make_event(data) do
    data = Jason.encode!(data)
    uuid = UUID.uuid4()
    "event: message\ndata: #{data}\nid: #{uuid}\nretry: 100\n\n"
  end

  defp send_event(event, channel) do
    Phoenix.PubSub.broadcast(Pushy.PubSub, channel, {:sse, event})
  end

  defp err_json(message) do
    Jason.encode!(%{error: message})
  end

  defp beautify_stack(stack) do
    Enum.map(stack, &Exception.format_stacktrace_entry/1) |> Enum.join("\n")
  end
end
