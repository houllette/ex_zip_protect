defmodule ExZipProtect.SenderHTTPTest do
  use ExUnit.Case, async: true
  import Plug.Test
  alias ExZipProtect.Sender.HTTP

  setup do
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "HELLO")
    end)

    url = "http://localhost:#{bypass.port}/bomb"
    conn = conn(:get, "/")
    spec = %{source: {:url, url}, encoding: :gzip}
    {:ok, conn: conn, url: url, spec: spec}
  end

  test "fetches body from remote URL", %{conn: conn, spec: spec} do
    conn = HTTP.send(conn, spec.source |> elem(1))
    assert conn.status == 200
    assert conn.resp_body == "HELLO"
  end
end
