defmodule ExZipProtect.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias ExZipProtect.Plug

  setup do
    # Create a tiny bomb file on the fly
    {:ok, bomb_path} = Briefly.create()
    File.write!(bomb_path, "BOMB")

    # Baseline library config
    Application.put_env(:ex_zip_protect, :enabled?, true)
    Application.put_env(:ex_zip_protect, :rotation, :none)
    Application.put_env(:ex_zip_protect, :bypass_header, nil)

    Application.put_env(
      :ex_zip_protect,
      :levels,
      low: [%{source: {:file, bomb_path}, encoding: :gzip, bytes: 4}]
    )

    on_exit(fn ->
      for key <- [:levels, :bypass_header, :enabled?, :rotation] do
        Application.delete_env(:ex_zip_protect, key)
      end
    end)

    %{bomb_path: bomb_path}
  end

  test "serves bomb and halts", %{bomb_path: _} do
    conn = conn(:get, "/") |> Plug.send(:low)

    assert conn.halted
    assert conn.status == 200
    assert get_resp_header(conn, "content-encoding") == ["gzip"]
    assert get_resp_header(conn, "content-length") == ["4"]
  end

  test "does nothing when library disabled", %{bomb_path: _} do
    Application.put_env(:ex_zip_protect, :enabled?, false)

    conn = conn(:get, "/") |> Plug.send(:low)
    refute conn.halted
    refute get_resp_header(conn, "content-encoding") == ["gzip"]
  end

  test "bypass header skips bomb", %{bomb_path: _} do
    Application.put_env(:ex_zip_protect, :bypass_header, "x-bypass")

    conn =
      conn(:get, "/")
      |> put_req_header("x-bypass", "1")
      |> Plug.send(:low)

    refute conn.halted
  end
end
