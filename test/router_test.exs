defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Pushy.Router

  setup do
    {:ok, valid_token} =
      Pushy.Auth.make_token(%{"sub" => "1234567890", "name" => "John Doe", "admin" => true})

    {:ok, valid_token: valid_token}
  end

  test "publishes to a channel", %{valid_token: valid_token} do
    conn =
      :post
      |> conn("/publish/test", %{data: %{message: "hello"}})
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Router.call([])

    assert conn.resp_body == ""
    assert conn.status == 200
  end

  test "returns 404 for unknown routes", %{valid_token: valid_token} do
    conn =
      :get
      |> conn("/unknown")
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Router.call([])

    assert conn.status == 404
  end

  test "handles invalid publish request", %{valid_token: valid_token} do
    conn =
      :post
      |> conn("/publish", %{})
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Router.call([])

    assert conn.status == 404
  end

  test "handles invalid SSE request", %{valid_token: valid_token} do
    conn =
      :post
      |> conn("/sse", %{})
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Router.call([])

    assert conn.status == 400
  end
end
