Mix.install([:httpoison, :jason])

defmodule EventPublisher do
  def publish(url, channel, data) do
    body = Jason.encode!(%{"data" => data})

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization",
       "Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxfQ.rINrV4jad74K9b1W39TEKlqXpG63h-dn-yfqQpVEztuhomwW4lZ36j6cKl9IXLiq43zvmNjBlMOA_aCbgofQOg"}
    ]

    HTTPoison.post("#{url}/publish/#{channel}", body, headers)
  end
end

url = "http://localhost:4000"
channel = "order.us.deliver"

data = %{
  "message" => "Hello, SSE! Your order is delivered!",
  "user_id" => 1,
  "item_title" => "Elixir in Action",
  "item_type" => "book",
  "item_id" => 1,
  "quantity" => 1,
  "total" => 10.0,
  "currency" => "USD"
}

case EventPublisher.publish(url, channel, data) do
  {:ok, response} -> IO.inspect(response)
  {:error, error} -> IO.inspect(error)
end
