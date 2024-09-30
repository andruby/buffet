# Sinatra app to demo Bank transactions to AI advice
require "bundler"
Bundler.require
Dotenv.load

require 'erb'
require 'securerandom'
require "sinatra/cookies"

set :bind, '0.0.0.0'

CLAUDE_MODEL = "claude-3-5-sonnet-20240620" # "claude-3-haiku-20240307" (cheaper <$0.005) or "claude-3-5-sonnet-20240620" (better, $0.02)
MAX_TOKENS = 1000
PROMPT = <<~EOP
You are a financial advisor.
You are give a list of recent transactions of a person in JSON format.
What can you say about this persons expenses and budgetting?

Reply in markdown format and be brief
EOP

get '/' do
  erb :index
end

get '/institutions' do
  @institutions = nordigen_client.institution.get_institutions("BE")
  erb :institutions
end

post '/init_requisition' do
  ref = SecureRandom.uuid # unique reference
  init = nordigen_client.init_session(
    # redirect url after successful authentication
    redirect_url: "http://#{request.env["SERVER_NAME"]}:4567/after_requisition",
    institution_id: params[:institution_id],
    reference_id: ref,
  )
  cookies[:gc_ref] = ref
  cookies[:requisition_id] = init["id"]
  redirect(init["link"])
end

get '/accounts' do
  @accounts = get_accounts(cookies[:requisition_id]).map do |account|
    # details = account.get_details()["account"] # rate limit = 4/day
    # balances = account.get_balances()["balances"] # rate limit = 4/day
    {
      id: account.account_id,
      # iban: details["iban"],
      # currency: details["currency"],
      # balance: balances&.first&.dig("balanceAmount", "acount")
    }
  end

  if @accounts.count == 0
    # clear cookies if we failed to get accounts
    cookies.keep_if { false }
  end

  erb :accounts
end

get '/account/:account_id' do
  content_type "text/vnd.turbo-stream.html"
  @account_id = params[:account_id]
  erb(:account)
end

get '/account/:account_id/advice' do
  raw_txs = nordigen_client.account(params[:account_id]).get_transactions()
  txs = raw_txs["transactions"]["booked"].map { |x| x.except("transactionId","internalTransactionId","proprietaryBankTransactionCode") }
  # txs = JSON.parse(File.read("txs.json"))
  content_type "text/event-stream"

  id = 1
  stream do |out|
    ask_claude(PROMPT, txs[0..20].to_json) do |full, delta|
      out << "id: #{id+=1}\ndata: #{delta.gsub("\n","\ndata: ")}\n\n"
    end
    out << "event: close\ndata: close\n\n"
  end
end

get '/after_requisition' do
  redirect to('/')
end

def get_accounts(req_id)
  client = nordigen_client
  requisition_data = client.requisition.get_requisition_by_id(req_id)
  requisition_data["accounts"].map { |account_id| client.account(account_id) }
end

def nordigen_client
  client = Nordigen::NordigenClient.new(
    secret_id: ENV.fetch("GOCARDLESS_SECRET_ID"),
    secret_key: ENV.fetch("GOCARDLESS_SECRET_KEY"),
  )
  token_data = client.generate_token()
  client.set_token(token_data["access"])
  client
end

def anthropic_client
  Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY"))
end

def ask_claude(system, message, &block)
  puts "asking claude"
  anthropic_client.messages(
    parameters: {
      model: CLAUDE_MODEL,
      system: system,
      messages: [{"role": "user", "content": message}],
      max_tokens: MAX_TOKENS,
      stream: block,
      preprocess_stream: :text
    })
end