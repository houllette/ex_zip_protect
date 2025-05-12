defmodule ExZipProtect.Sender.S3 do
  @moduledoc false
  import Plug.Conn, only: [send_chunked: 2, chunk: 2]

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

    stream = client.get_object(bucket, key, opts)
    conn = send_chunked(conn, 200)

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
end
