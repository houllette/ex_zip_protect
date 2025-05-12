defmodule ExZipProtect.ResolverTest do
  use ExUnit.Case, async: true

  alias ExZipProtect.{Config, Resolver}

  setup do
    bombs = for i <- 1..3, do: %{source: {:file, "/tmp/#{i}"}, encoding: :gzip}
    Application.put_env(:ex_zip_protect, :levels, demo: bombs)

    on_exit(fn -> Application.delete_env(:ex_zip_protect, :levels) end)
    :ok
  end

  test "rotation :none picks first" do
    Application.put_env(:ex_zip_protect, :rotation, :none)
    assert Resolver.fetch(:demo) == hd(Config.levels()[:demo])
  end

  test "rotation :random returns one of items" do
    Application.put_env(:ex_zip_protect, :rotation, :random)
    assert Resolver.fetch(:demo) in Config.levels()[:demo]
  end

  test "rotation :round_robin cycles" do
    Application.put_env(:ex_zip_protect, :rotation, :round_robin)

    # create the table if another test started the app without it
    unless :ets.whereis(:ex_zip_protect_rr) != :undefined do
      :ets.new(
        :ex_zip_protect_rr,
        [:set, :public, :named_table, read_concurrency: true]
      )
    end

    # reset counter for predictable order
    :ets.delete_all_objects(:ex_zip_protect_rr)

    list = Config.levels()[:demo]

    first = Resolver.fetch(:demo)
    second = Resolver.fetch(:demo)
    third = Resolver.fetch(:demo)

    # we received each unique item exactly once (order may vary)
    assert Enum.sort([first, second, third]) == Enum.sort(list)

    # fourth call should wrap back to the first element we saw
    assert Resolver.fetch(:demo) == first
  end
end
