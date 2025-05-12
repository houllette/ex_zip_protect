defmodule ExZipProtect.Plug do
  @moduledoc """
  Public entry point for serving pre‑built “zip bombs”.

      alias ExZipProtect.Plug, as: Bomb
      Bomb.send(conn, :medium)

  * **No‑op** if the library is disabled (`enabled?: false` in config).
  * **Bypass** if the request carries the user‑defined `bypass_header`.
  * Otherwise looks up the bomb spec for the given *level*, sets the
    required response headers, streams the payload, and halts the
    connection pipeline.
  """

  import Plug.Conn, only: [put_resp_header: 3, halt: 1]
  alias ExZipProtect.{Config, Resolver, Sender}

  @doc """
  Sends a bomb for `level` (`:low | :medium | :high | …`) and halts
  the Plug pipeline. Optional `extra_headers` are merged into the
  response.
  """
  @spec send(Plug.Conn.t(), atom(), keyword()) :: Plug.Conn.t()
  def send(conn, level, extra_headers \\ []) do
    cond do
      not Config.enabled?() ->
        conn

      bypass?(conn) ->
        conn

      true ->
        spec = Resolver.fetch(level)

        conn
        |> put_resp_header("content-encoding", Atom.to_string(spec.encoding))
        |> maybe_put_length(spec)
        |> merge_extra_headers(extra_headers)
        |> Sender.dispatch(level, spec)
        |> halt()
    end
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp merge_extra_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {k, v}, acc -> put_resp_header(acc, k, v) end)
  end

  defp maybe_put_length(conn, %{bytes: bytes}) when is_integer(bytes) do
    put_resp_header(conn, "content-length", Integer.to_string(bytes))
  end

  defp maybe_put_length(conn, _), do: conn

  # True if the request contains the user‑configured bypass header.
  defp bypass?(conn) do
    case Config.bypass_header() do
      nil -> false
      "" -> false
      name -> conn |> Plug.Conn.get_req_header(name) |> Enum.any?()
    end
  end
end
