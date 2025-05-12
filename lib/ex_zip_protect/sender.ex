defmodule ExZipProtect.Sender do
  @moduledoc false
  alias ExZipProtect.Sender.{File, HTTP, S3}

  def dispatch(conn, level, spec) do
    :telemetry.execute(
      [:ex_zip_protect, :bomb, :served],
      %{bytes: Map.get(spec, :bytes, :unknown)},
      %{level: level, ip: ip(conn), source: spec.source}
    )

    case spec.source do
      {:file, path} -> File.send(conn, path)
      {:s3, _kw} -> S3.send(conn, spec)
      {:url, url} when is_binary(url) -> HTTP.send(conn, url)
      other -> raise ArgumentError, "Unsupported source #{inspect(other)}"
    end
  end

  defp ip(conn) do
    if function_exported?(Plug.Conn, :get_peer_data, 1) do
      Plug.Conn.get_peer_data(conn).address |> :inet.ntoa() |> List.to_string()
    else
      conn.remote_ip |> :inet.ntoa() |> List.to_string()
    end
  end
end
