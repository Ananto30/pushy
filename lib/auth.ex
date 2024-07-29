defmodule Pushy.Auth do
  import Plug.Conn

  @secret System.get_env("AUTH_SECRET_KEY") || raise("AUTH_SECRET_KEY not set")
  @alg "HS512"
  @signer Joken.Signer.create(@alg, @secret)

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> get_token()
    |> authenticate()
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, conn, token}
      _ -> {:error, conn}
    end
  end

  def make_token(claims) do
    Joken.Signer.sign(claims, @signer)
  end

  defp authenticate({:ok, conn, token}) do
    case Joken.verify(token, @signer) do
      {:ok, claims} -> handle_claims(conn, claims)
      {:error, reason} -> send_401(conn, %{message: reason})
    end
  end

  defp authenticate({:error, conn}) do
    send_401(conn)
  end

  defp handle_claims(conn, claims) do
    if token_expired?(claims) do
      send_401(conn, %{message: "Token expired"})
    else
      conn
      |> assign(:claims, claims)
      |> assign(:user_id, claims["user_id"])
    end
  end

  defp send_401(conn, data \\ %{message: "Please make sure you have authentication header"}) do
    conn
    |> put_status(:unauthorized)
    |> errjson(data)
    |> halt()
  end

  defp token_expired?(claims) do
    case Map.get(claims, "exp") do
      nil -> false
      exp -> exp < :os.system_time(:seconds)
    end
  end

  defp errjson(conn, data) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(:unauthorized, Jason.encode!(data))
  end
end
