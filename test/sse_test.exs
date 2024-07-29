defmodule SSETest do
  use ExUnit.Case
  use Plug.Test

  alias Pushy.Router

  setup do
    {:ok, valid_token} =
      Pushy.Auth.make_token(%{"sub" => "1234567890", "name" => "John Doe", "admin" => true})

    {:ok, valid_token: valid_token}
  end

  test "receives a message", %{valid_token: valid_token} do
    # Start the SSE connection in a separate task
    receiver_task =
      Task.async(fn ->
        HTTPoison.post!(
          "http://localhost:4000/sse",
          Jason.encode!(%{channels: ["test"]}),
          [
            {"Authorization", "Bearer #{valid_token}"},
            {"Connection", "keep-alive"},
            {"Accept", "text/event-stream"},
            {"Cache-Control", "no-cache"}
          ],
          stream_to: self()
        )
      end)

    # Ensure the SSE connection is established
    :timer.sleep(1000)

    sender_conn =
      :post
      |> conn("/publish/test", %{data: %{message: "hello"}})
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Router.call([])

    assert sender_conn.status == 200

    receive do
      %HTTPoison.Error{reason: reason} ->
        flunk("Failed to connect: #{inspect(reason)}")

      %HTTPoison.AsyncChunk{chunk: chunk} ->
        assert chunk == "data: {\"message\":\"hello\"}\n\n"
    after
      1000 -> flunk("Did not receive SSE message in time")
    end

    Task.shutdown(receiver_task, :brutal_kill)
  end
end
