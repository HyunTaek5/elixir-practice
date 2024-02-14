defmodule ElixirPractice.Application do
  @moduledoc """
  Main entry point of the app
  """

  use Application

  def start(_type, _args) do
    children = [
      ElixirPractice.Repo,
      {Phoenix.PubSub, [name: ElixirPractice.PubSub, adapter: Phoenix.PubSub.PG2]},
      ElixirPracticeWeb.Endpoint,
      {TelemetryUI, ElixirPractice.TelemetryUI.config()}
    ]

    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

    opts = [strategy: :one_for_one, name: ElixirPractice.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ElixirPracticeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
