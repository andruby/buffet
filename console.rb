require "bundler"
Bundler.require

Dotenv.load

@gc_client = GoCardlessPro::Client.new(
  access_token: ENV["GOCARDLESS_TOKEN"],
  environment: :sandbox,
)

@nordigen_client = Nordigen::NordigenClient.new(
  secret_id: ENV["GOCARDLESS_SECRET_ID"],
  secret_key: ENV["GOCARDLESS_SECRET_KEY"],
)

