class Synchronizer
  include StaticService

  def call
    loop do
      Setting.get('sync_exchanges', []).each { |exchange| PantiniArbitrageParser.connect exchange }
      Setting.save 'sync_books', ArbitrageCase.current_tickers
      Setting.get('sync_books', []).each { |ticker| Orderbook.sync ticker }
      puts "..."
      sleep 4
    end
  end
end

__END__
