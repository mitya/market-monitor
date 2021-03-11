class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def quote(symbol)
    get "/stock/#{symbol}/quote"
  end

  def insider_transactions(symbol)
    get "/stock/#{symbol}/insider-transactions"
  end

  def options(symbol)
    get "/stock/#{symbol}/options"
  end

  def recommedations(symbol)
    get "/stock/#{symbol}/recommendation-trends"
  end

  def last(symbol)
    get "/last?symbols=#{symbol}"
  end

  def logo(symbol)
    get "/stock/#{symbol}/logo"
  end

  private

  def get(path)
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }
    JSON.parse response.body
  end
end

__END__
IexConnector.logo 'BRK.B'
