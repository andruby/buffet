require "bundler"
Bundler.require

Dotenv.load

client = Nordigen::NordigenClient.new(
  secret_id: ENV["GOCARDLESS_SECRET_ID"],
  secret_key: ENV["GOCARDLESS_SECRET_KEY"],
)

# Generate new access token. Token is valid for 24 hours
token_data = client.generate_token()

client.set_token(token_data["access"])

# institutions = client.institution.get_institutions("BE")

kbc_id = "KBC_KREDBEBB"

ref = "rfds422"
init = client.init_session(
  # redirect url after successful authentication
  redirect_url: "http://andrewsblog.org",
  institution_id: kbc_id,
  # a unique user ID of someone who's using your services, usually it's a UUID
  reference_id: ref,
)

link = init["link"] # bank authorization link
puts "link: #{link.inspect}"
requisition_id = init["id"]
puts "requisition_id: #{requisition_id.inspect}" 