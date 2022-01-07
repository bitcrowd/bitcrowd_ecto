defmodule BitcrowdEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcrowd_ecto,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      deps_path: "_deps",
      dialyzer: dialyzer(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [lint: :test]
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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.7", only: [:dev, :test]},
      {:postgrex, "> 0.0.0", only: [:dev, :test]}
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
