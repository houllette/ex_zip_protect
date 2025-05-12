defmodule ExZipProtect.SenderS3Test do
  use ExUnit.Case, async: true
  import Plug.Test
  import Mox

  alias ExZipProtect.Adapters.S3ClientMock
  alias ExZipProtect.Sender.S3

  setup :verify_on_exit!

  setup do
    Application.put_env(:ex_zip_protect, :s3_client, S3ClientMock)

    S3ClientMock
    |> expect(:get_object, fn "b", "k", _opts -> ["ABC", "DEF"] end)

    spec = %{source: {:s3, bucket: "b", key: "k"}, encoding: :gzip}
    {:ok, conn: conn(:get, "/"), spec: spec}
  end

  test "streams S3 object into response", %{conn: conn, spec: spec} do
    conn = S3.send(conn, spec)
    assert conn.status == 200
    assert conn.resp_body == "ABCDEF"
  end
end
