defmodule Mix.ExZipProtect.GenConfigTest do
  use ExUnit.Case, async: false

  @config_path Path.join(["config", "ex_zip_protect.exs"])

  setup do
    File.rm_rf!("config")
    :ok
  end

  test "generator creates scaffold file" do
    Mix.Task.rerun("ex_zip_protect.gen.config")

    assert File.exists?(@config_path)
    assert File.read!(@config_path) =~ "ex_zip_protect — sample configuration"
  end
end
