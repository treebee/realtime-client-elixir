defmodule RealtimeClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :realtime_client,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
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
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end
end
