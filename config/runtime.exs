import Config

if database_url = System.get_env("DATABASE_URL") do
  config :bitcrowd_ecto, BitcrowdEcto.TestRepo, url: database_url
end
