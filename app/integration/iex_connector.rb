class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def quote(ticker)
    get "/stock/#{ticker}/quote"
  end

  def insider_transactions(ticker)
    get "/stock/#{ticker}/insider-transactions"
  end

  def options(ticker)
    get "/stock/#{ticker}/options"
  end

  def recommedations(ticker)
    get "/stock/#{ticker}/recommendation-trends"
  end

  def last(ticker)
    get "/last?symbols=#{ticker}"
  end

  private

  def get(path)
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }
    JSON.parse response.body
  end
end
