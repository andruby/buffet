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

@anthorpic_client = Anthropic::Client.new(
  access_token: ENV.fetch("ANTHROPIC_API_KEY")
)

def anthropic_client
  Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY"))
end

def ask_claude(system, message, &block)
  anthropic_client.messages(
    parameters: {
      model: "claude-3-haiku-20240307",
      system: system,
      messages: [{"role": "user", "content": message}],
      max_tokens: 1000,
      stream: block,
      preprocess_stream: :text
    })
end
