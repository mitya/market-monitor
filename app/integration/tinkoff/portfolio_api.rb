class Tinkoff
  concerning :PortfolioApi do
    def sync_portfolio(data, account)
      puts "Sync tinkoff portfolio '#{account}'"
      data['positions'].to_a.each do |position|
        ticker = position['ticker']
        next if position['instrumentType'] == 'Currency'
        next puts "Missing #{ticker} (used in portfolio)".red if !Instrument.get(ticker)
        item = PortfolioItem.find_or_create_by(ticker: ticker)
        item.update! "#{account}_lots" => position['balance'],
          "#{account}_average" => position.dig('averagePositionPrice', 'value'),
          "#{account}_yield" => position.dig('expectedYield', 'value')
      end
      PortfolioItem.where.not(ticker: data['positions'].map { |p| p['ticker'] }).find_each do |item|
        puts "Missing #{item.instrument} (which is in portfolio)".red unless item.instrument
        next if item.instrument&.premium?
        item.update! "#{account}_lots" => nil
      end
    end

    def sync_portfolios
      sync_portfolio call_js_api("portfolio"), 'tinkoff'
      sync_portfolio call_js_api("portfolio", account: 'iis'), 'tinkoff_iis'
      cleanup_portfolio
    end

    def sync_iis
      sync_portfolio call_js_api("portfolio", account: 'iis'), 'tinkoff_iis'
    end

    def cleanup_portfolio
      PortfolioItem.find_each.select { |pi| pi.total_lots == 0 }.each &:destroy
    end
  end
end