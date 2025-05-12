defmodule ExZipProtect.Resolver do
  @moduledoc false
  @rr_table :ex_zip_protect_rr

  def fetch(level) do
    list =
      ExZipProtect.Config.levels()[level] ||
        raise ArgumentError, "Unknown level #{inspect(level)}"

    rotate(list, ExZipProtect.Config.rotation())
  end

  # ────────────────────────────────────────────────────────────────────
  # single item fast‑path
  defp rotate([spec], _), do: spec
  defp rotate(list, :none), do: hd(list)
  defp rotate(list, nil), do: hd(list)
  defp rotate(list, :random), do: Enum.random(list)
  defp rotate(list, :round_robin), do: rr(list)

  defp rr(list) do
    key = {:rr, list}
    idx = :ets.update_counter(@rr_table, key, {2, 1}, {key, seed()})
    Enum.at(list, rem(idx, length(list)))
  end

  defp seed, do: System.unique_integer([:positive])
end
