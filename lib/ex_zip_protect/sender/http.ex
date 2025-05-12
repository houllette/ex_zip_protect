defmodule ExZipProtect.Sender.HTTP do
  @moduledoc false
  import Plug.Conn

  @finch ExZipProtectFinch

  def send(conn, url) do
    ensure_dep!(:finch)

    {:ok, %Finch.Response{body: body, status: 200, headers: hdrs}} =
      Finch.build(:get, url) |> Finch.request(@finch)

    conn = Enum.reduce(hdrs, conn, fn {k, v}, acc -> put_resp_header(acc, k, v) end)
    send_resp(conn, 200, body)
  end

  defp ensure_dep!(app) do
    unless Code.ensure_loaded?(Finch) do
      raise "Add #{app} to your deps to use URL sources"
    end
  end
end
