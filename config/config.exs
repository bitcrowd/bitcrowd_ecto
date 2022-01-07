import Config

if config_env() in [:dev, :test] do
  config :bitcrowd_ecto, BitcrowdEcto.TestRepo,
    migration_timestamps: [type: :utc_datetime_usec],
    migration_primary_key: [name: :id, type: :binary_id],
    database: "bitcrowd_ecto_#{config_env()}",
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    priv: "test/support/test_repo"

  config :bitcrowd_ecto, ecto_repos: [BitcrowdEcto.TestRepo]
end

if config_env() == :test do
  # Set to :debug to see SQL logs.
  config :logger, level: :info

  config :bitcrowd_ecto, BitcrowdEcto.TestRepo, pool: Ecto.Adapters.SQL.Sandbox
end
