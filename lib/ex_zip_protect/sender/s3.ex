defmodule ExZipProtect.Sender.S3 do
  @moduledoc false
  import Plug.Conn, only: [send_chunked: 2, chunk: 2, put_resp_header: 3]

  def send(conn, %{source: {:s3, kw}}) do
    ensure_dep!(:ex_aws_s3)

    client =
      Application.get_env(
        :ex_zip_protect,
        :s3_client,
        ExZipProtect.Adapters.S3Client.ExAws
      )

    bucket = Keyword.fetch!(kw, :bucket)
    key = Keyword.fetch!(kw, :key)
    opts = Keyword.get(kw, :opts, [])

    bytes =
      with {:ok, %{headers: hdrs}} <- client.head_object(bucket, key, opts),
           {"Content-Length", v} <- Enum.find(hdrs, &match?({"Content-Length", _}, &1)),
           {int, _} <- Integer.parse(v) do
        int
      else
        _ -> nil
      end

    stream = client.get_object(bucket, key, opts)

    conn =
      conn
      |> maybe_len(bytes)
      |> send_chunked(200)

    Enum.reduce_while(stream, conn, fn chunk, acc ->
      case chunk(acc, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, :closed} -> {:halt, acc}
      end
    end)
  end

  defp ensure_dep!(app) do
    unless Code.ensure_loaded?(ExAws.S3) do
      raise "Add #{app} to your deps to use S3 sources"
    end
  end

  defp maybe_len(conn, nil), do: conn

  defp maybe_len(conn, bytes),
    do: put_resp_header(conn, "content-length", Integer.to_string(bytes))
end
