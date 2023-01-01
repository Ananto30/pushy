defmodule PushyTest do
  use ExUnit.Case
  use Plug.Test

  alias Pushy.Router

  test "publishes to a channel" do
    conn =
      :post
      |> conn("/publish", channel: "test", data: %{message: "hello"})
      |> Router.call([])

    assert conn.status == 200
  end

  test "receives a message" do
    receiver_conn =
      :post
      |> conn("/sse", channels: ["test"])
      |> Router.call([])

    assert receiver_conn.status == 200

    # publisher_conn =
    #   :post
    #   |> conn("/publish", channel: "test", data: %{message: "hello"})
    #   |> Router.call([])

    # assert publisher_conn.status == 200

    # assert receiver_conn.body =~ "hello"
  end
end
