defmodule Mix.Tasks.ExZipProtect.Gen.Config do
  @moduledoc """
  Generates a starter configuration file for the `ex_zip_protect` library.

  The `mix ex_zip_protect.gen.config` task will create
  `config/ex_zip_protect.exs` populated with sensible defaults
  for:

    * `enabled?`      – whether bombs are served (default: prod only)
    * `rotation`      – bomb rotation strategy (`:none`, `:random`, `:round_robin`)
    * `bypass_header` – optional header to skip serving bombs
    * `levels`        – definitions of bomb levels and sources (file, S3, URL)

  ## Usage

      mix ex_zip_protect.gen.config

  This task will abort if `config/ex_zip_protect.exs` already exists.
  """
  use Mix.Task
  @shortdoc "Creates config/ex_zip_protect.exs with starter settings"

  @config "config/ex_zip_protect.exs"

  @template """
  # --------------------------------------------------------------------
  # ex_zip_protect — sample configuration
  # --------------------------------------------------------------------

  import Config

  config :ex_zip_protect,
    enabled?: config_env() == :prod,
    rotation: :none,  # :none | :random | :round_robin
    # bypass_header: "x-zipprotect-skip",  # any request with this header bypasses bombs, uncomment to enable
    levels: [
      low: [
        %{
          source: {:file, "/srv/bombs/low.gz"},
          encoding: :gzip
        }
      ],
      medium: [
        %{
          source: {:s3,
            bucket: "my-bomb-bucket",
            key: "5mb-zstd.zst",
            opts: [region: "us-west-2"]
          },
          encoding: :zstd
        }
      ],
      high: [
        %{
          source: {:url, "https://cdn.example.com/10mb.br"},
          encoding: :br
        }
      ]
    ]
  """

  @impl true
  def run(_args) do
    Mix.shell().info("* writing #{@config}")

    if File.exists?(@config), do: Mix.raise("File already exists; aborting.")

    File.mkdir_p!("config")
    File.write!(@config, @template)
    Mix.shell().info([:green, "✓ ", :reset, "created #{@config}"])
  end
end
