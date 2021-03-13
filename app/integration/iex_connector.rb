# https://iexcloud.io/console/
# https://iexcloud.io/docs/api
class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def quote(symbol) = get("/stock/#{symbol}/quote")
  def last(symbol) = get("/last?symbols=#{symbol}")

  def insider_transactions(symbol) = get("/stock/#{symbol}/insider-transactions")
  def options(symbol) = get("/stock/#{symbol}/options")
  def recommedations(symbol) = get("/stock/#{symbol}/recommendation-trends")
  def logo(symbol) = get("/stock/#{symbol}/logo")
  def company(symbol) = get("/stock/#{symbol}/company")
  def stats(symbol) = get("/stock/#{symbol}/stats")

  private

  def get(path)
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }
    p response
    JSON.parse response.body
  end
end

__END__
IexConnector.logo 'BRK.B'
IexConnector.company 'FANG'
IexConnector.stats 'FANG'
