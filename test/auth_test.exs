defmodule Pushy.AuthTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Pushy.Auth

  @opts Auth.init([])

  setup do
    {:ok, valid_token} =
      Auth.make_token(%{"sub" => "1234567890", "name" => "John Doe", "admin" => true})

    {:ok, expired_token} =
      Auth.make_token(%{"sub" => "1234567890", "name" => "John Doe", "admin" => true, "exp" => 0})

    invalid_token = "invalid.token.value"
    {:ok, valid_token: valid_token, expired_token: expired_token, invalid_token: invalid_token}
  end

  test "authenticates with a valid token", %{valid_token: valid_token} do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer #{valid_token}")
      |> Auth.call(@opts)

    assert conn.status != 401
  end

  test "returns 401 with an expired token", %{expired_token: expired_token} do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer #{expired_token}")
      |> Auth.call(@opts)

    assert conn.status == 401
    assert conn.resp_body =~ "Token expired"
  end

  test "returns 401 with an invalid token", %{invalid_token: invalid_token} do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer #{invalid_token}")
      |> Auth.call(@opts)

    assert conn.status == 401
  end

  test "returns 401 without a token" do
    conn =
      conn(:get, "/")
      |> Auth.call(@opts)

    assert conn.status == 401
  end
end
