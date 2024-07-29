Mix.install([:httpoison, :jason])

defmodule SSEClient do
  # Retry interval in milliseconds
  @retry_interval 5000

  def connect(url, channels) do
    headers = [
      {"Accept", "text/event-stream"},
      {"Content-Type", "application/json"},
      {"Cache-Control", "no-cache"},
      {"Connection", "keep-alive"},
      {"Authorization",
       "Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxfQ.rINrV4jad74K9b1W39TEKlqXpG63h-dn-yfqQpVEztuhomwW4lZ36j6cKl9IXLiq43zvmNjBlMOA_aCbgofQOg"}
    ]

    body = Jason.encode!(%{"channels" => channels})
    options = [stream_to: self(), recv_timeout: :infinity]

    case HTTPoison.post(url, body, headers, options) do
      {:ok, _} ->
        IO.puts("Connected to #{url}")
        receive_events(url, channels)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Failed to connect: #{inspect(reason)}. Retrying in #{@retry_interval}ms...")
        :timer.sleep(@retry_interval)
        connect(url, channels)
    end
  end

  defp receive_events(url, channels) do
    receive do
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        IO.puts("Received chunk: #{chunk}")
        receive_events(url, channels)

      %HTTPoison.AsyncEnd{} ->
        IO.puts("Stream ended. Reconnecting...")
        :timer.sleep(@retry_interval)
        connect(url, channels)

      %HTTPoison.Error{reason: reason} ->
        IO.puts("Connection error: #{inspect(reason)}. Reconnecting...")
        :timer.sleep(@retry_interval)
        connect(url, channels)
    end
  end
end

url = "http://localhost:4000/sse"
SSEClient.connect(url, ["order.us.deliver", "order.eu.deliver"])
