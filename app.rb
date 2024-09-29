# Sinatra app to demo Bank transactions to AI advice
require "bundler"
Bundler.require
Dotenv.load

require 'erb'

get '/' do
  erb :index
end

get '/institutions' do
  @institutions = nordigen_client.institution.get_institutions("BE")
  erb :institutions
end

def nordigen_client
  client = Nordigen::NordigenClient.new(
    secret_id: ENV["GOCARDLESS_SECRET_ID"],
    secret_key: ENV["GOCARDLESS_SECRET_KEY"],
  )
  token_data = client.generate_token()
  client.set_token(token_data["access"])
  client
end