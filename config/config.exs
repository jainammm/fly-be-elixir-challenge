# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fly,
  ecto_repos: [Fly.Repo]

# Configures the endpoint
config :fly, FlyWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: FlyWeb.ErrorHTML, json: FlyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Fly.PubSub,
  live_view: [signing_salt: "AwM9jJSB"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :fly, Fly.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :fly, Oban,
  repo: Fly.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 2, sync_invoice_item: 2]    # maximum number of concurrent jobs for each event

# SmartEngine enables truly global concurrency and global rate limiting
# This is a Oban Pro feature.
# ### Docs: https://hexdocs.pm/oban/2.11.0/smart_engine.html
# ### Example config would look like:
#   queues: [
#     default: 2,
#     sync_invoice_item: [local_limit: 2, global_limit: 10, rate_limit: [allowed: 500, period: {1, :hour}]
#   ]

config :fly,
  max_attemps_sync_invoice_item: 3,              # maximum retries for job
  max_execution_time_sync_invoice_item: 5       # maximum time in seconds for job

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
