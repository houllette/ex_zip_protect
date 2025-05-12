defmodule ExZipProtect.MixProject do
  use Mix.Project

  @source_url "https://github.com/houllette/ex_zip_protect"
  @version "0.1.1"

  def project do
    [
      app: :ex_zip_protect,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      package: package(),
      description: "Playful way to protect your Phoenix apps from bots and abuse",
      name: "ExZipProtect",
      homepage_url: @source_url,
      docs: docs(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :telemetry],
      mod: {ExZipProtect.Application, []}
    ]
  end

  defp deps do
    [
      # Core Dependencies
      {:plug, "~> 1.17"},

      # Optional Dependencies
      {:ex_aws, "~> 2.5", optional: true},
      {:ex_aws_s3, "~> 2.5", optional: true},
      {:finch, "~> 0.19", optional: true},

      # Dev / Test Dependencies
      {:ex_doc, "~> 0.37", only: :dev},
      {:credo, "~> 1.7.12", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.2", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:briefly, "~> 0.5", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Holden Oullette"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp aliases do
    [
      "test.all": [
        "hex.audit",
        "format --check-formatted",
        "compile --warnings-as-errors",
        "deps.unlock --check-unused",
        "credo --all --strict"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
