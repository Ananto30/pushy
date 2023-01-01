defmodule Pushy.Auth do
  import Plug.Conn

  @secret "secret"
  @alg "HS256"
  @signer Joken.Signer.create(@alg, @secret)

  def init(opts), do: opts

  defp authenticate({conn, "Bearer " <> token}) do
    case Joken.verify(token, @signer) do
      {:ok, claims} ->
        assign(conn, :claims, claims)
        assign(conn, :user_id, claims["user_id"])

      {:error, reason} ->
        send_401(conn, %{message: reason})
    end
  end

  defp authenticate({conn, _}) do
    send_401(conn)
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      [token] -> {conn, token}
      _ -> {conn, nil}
    end
  end

  defp send_401(
         conn,
         data \\ %{message: "Please make sure you have authentication header"}
       ) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(data))
    |> halt
  end

  def call(conn, _opts) do
    conn
    |> get_token()
    |> authenticate()
  end
end
