import Config

version = Mix.Project.config()[:version]

config :elixir_practice,
  ecto_repos: [ElixirPractice.Repo],
  version: version

config :phoenix, :json_library, Jason

config :elixir_practice, ElixirPracticeWeb.Endpoint,
  pubsub_server: ElixirPractice.PubSub,
  render_errors: [view: ElixirPracticeWeb.Errors, accepts: ~w(html json)]

config :elixir_practice, ElixirPractice.Repo,
  migration_primary_key: [type: :binary_id, default: {:fragment, "gen_random_uuid()"}],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:ssl]

config :elixir_practice, Corsica, allow_headers: :all

config :elixir_practice, ElixirPractice.Gettext, default_locale: "en"

config :elixir_practice, ElixirPracticeGraphQL, token_limit: 2000

config :elixir_practice, ElixirPracticeWeb.Plugs.Security, allow_unsafe_scripts: false

config :esbuild,
  version: "0.16.4",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :sentry,
  included_environments: [:all],
  root_source_code_path: File.cwd!(),
  release: version

config :logger, backends: [:console, Sentry.LoggerBackend]

# Import environment configuration
import_config "#{Mix.env()}.exs"
