defmodule RealtimeClient.MixProject do
  use Mix.Project

  def project do
    [
      name: "Realtime Client",
      app: :realtime_client,
      version: "0.2.0",
      description: "A client for the Realtime (supabase/realtime) service.",
      elixir: "~> 1.11",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/treebee/realtime-client-elixir",
      homepage_url: "https://github.com/treebee/realtime-client-elixir",
      docs: [
        main: "RealtimeClient",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:phoenix_client, "~> 0.11.1"},
      {:ecto, "~> 3.6.2", only: :test},
      {:ecto_sql, "~> 3.6.2", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:excoveralls, "~> 0.13", only: :test},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "realtime_client",
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/treebee/realtime-client-elixir"},
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*)
    ]
  end
end
