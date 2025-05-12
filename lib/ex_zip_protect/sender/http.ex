defmodule ExZipProtect.Sender.HTTP do
  @moduledoc false
  import Plug.Conn

  @finch ExZipProtectFinch

  def send(conn, url) do
    ensure_dep!(:finch)

    bytes =
      with {:ok, %Finch.Response{status: 200, headers: hdrs}} <-
             Finch.build(:head, url) |> Finch.request(@finch),
           {"content-length", v} <- Enum.find(hdrs, &match?({"content-length", _}, &1)),
           {int, _} <- Integer.parse(v) do
        int
      else
        _ -> nil
      end

    {:ok, %Finch.Response{body: body, status: 200, headers: _hdrs}} =
      Finch.build(:get, url) |> Finch.request(@finch)

    conn
    |> maybe_len(bytes)
    |> send_resp(200, body)
  end

  defp maybe_len(conn, nil), do: conn

  defp maybe_len(conn, bytes),
    do: put_resp_header(conn, "content-length", Integer.to_string(bytes))

  defp ensure_dep!(app) do
    unless Code.ensure_loaded?(Finch) do
      raise "Add #{app} to your deps to use URL sources"
    end
  end
end
