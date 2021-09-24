class Synchronizer
  include StaticService

  def call
    loop do
      Setting.get('sync_exchanges', []).each { |exchange| PantiniArbitrageParser.connect exchange }
      Setting.save 'sync_books', ArbitrageCase.current_tickers(direction: 'up')
      Setting.get('sync_books', []).each { |ticker| Orderbook.sync ticker }
      Order.sync
      Operation.sync
      Tinkoff.sync_iis
      puts "..."
      sleep 4
    end
  end

  def sync_news
    loop do
      PantiniNewsParser.connect
      sleep 5
    end
  end
end

__END__
