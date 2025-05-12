defmodule ExZipProtect.SenderHTTPTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn
  alias ExZipProtect.Sender.HTTP

  setup do
    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "HELLO") |> put_resp_header("content-length", "5")
    end)

    url = "http://localhost:#{bypass.port}/bomb"
    spec = %{source: {:url, url}, encoding: :gzip}
    {:ok, conn: conn(:get, "/"), spec: spec}
  end

  test "fetches body from remote URL", %{conn: conn, spec: spec} do
    conn = HTTP.send(conn, spec.source |> elem(1))
    assert get_resp_header(conn, "content-length") == ["5"]
    assert conn.resp_body == "HELLO"
  end
end
