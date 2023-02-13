# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.MixProject do
  use Mix.Project

  @version "0.15.0"

  def project do
    [
      app: :bitcrowd_ecto,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [lint: :test],

      # hex.pm
      package: package(),
      description: "Bitcrowd's Ecto utilities",

      # hexdocs.pm
      docs: docs(),
      name: "bitcrowd_ecto",
      source_url: "https://github.com/bitcrowd/bitcrowd_ecto",
      homepage_url: "https://github.com/bitcrowd/bitcrowd_ecto"
    ]
  end

  defp package do
    [
      maintainers: ["@bitcrowd"],
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/bitcrowd/bitcrowd_ecto"}
    ]
  end

  defp docs do
    [
      main: "BitcrowdEcto",
      extras: ["LICENSE", "README.md", "CHANGELOG.md": [title: "Changelog"]],
      source_ref: "v#{@version}",
      source_url: "https://github.com/bitcrowd/bitcrowd_ecto",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      lint: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer --format dialyxir"
      ],
      "ecto.reset": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate"
      ]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.6"},
      {:ecto_sql, "~> 3.6"},
      {:ex_money, "~> 5.12", optional: true},
      {:ex_money_sql, "~> 1.7", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "> 0.0.0", only: [:dev], runtime: false},
      {:ex_machina, "~> 2.7", only: [:dev, :test]},
      {:junit_formatter, "~> 3.3", only: [:test]},
      {:postgrex, "> 0.0.0", only: [:dev, :test]},
      {:tzdata, "> 0.0.0", only: [:dev, :test]},
      # NOTE: https://github.com/kipcole9/money/issues/142
      {:jason, "> 0.0.0", optional: true}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_core_path: "_plts",
      plt_file: {:no_warn, "_plts/bitcrowd_ecto.plt"}
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
