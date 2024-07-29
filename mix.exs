defmodule Pushy.MixProject do
  use Mix.Project

  def project do
    [
      app: :pushy,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Pushy, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5.0"},
      {:jason, "~> 1.2.2"},
      {:uuid, "~> 1.1.8"},
      {:phoenix_pubsub, "~> 2.0.0"},
      {:joken, "~> 2.0.0"},
      {:httpoison, "~> 1.8", only: :test}
    ]
  end
end
