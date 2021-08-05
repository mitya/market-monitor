class PantiniArbitrageParser
  include StaticService

  def connect(exchange)
    puts "Sync arbitrages from #{exchange}"
    command = "coffee bin/telegram.coffee messages #{exchange}"
    response = `#{command}`
    parse_text response
  end

  def parse
    text = File.read "db/data/pantini-sample.txt"
  end

  def parse_text(text)
    text.gsub!(/(💰|🥛|‼️).*/, '')
    lines = text.split(/\n+/)
    lines = lines[1..-1]
    return if lines.blank?
    lines.reject! { |line| line.include?('Курс') }
    lines.reject! { |line| line.include?('Последнее обновление') }
    lines.reject! { |line| line.include?('Арбитражных ситуаций не обнаружено') }
    lines.reject! { |line| line.include?('Sync arbitrages from US') }

    groups = lines.in_groups_of(3)
    groups.each do |group|
      ticker_line, spb_line, foreign_line = group
      next if [ticker_line, spb_line, foreign_line].any?(&:blank?)

      long = ticker_line.include?('💚')
      delisted = ticker_line.include?('💤')

      ticker_line = ticker_line.delete('❤️💚💤()%').squish
      ticker, percent = ticker_line.split
      percent = percent.gsub(',', '.').to_f
      next unless Instrument.defined? ticker

      spb_exchange_code, spb_bid, spb_bid_size, spb_ask, spb_ask_size = parse_bid_ask_line(spb_line)
      foreign_exchange_code, foreign_bid, foreign_bid_size, foreign_ask, foreign_ask_size = parse_bid_ask_line(foreign_line)

      arb = ArbitrageCase.find_or_initialize_by ticker: ticker, date: Current.date, exchange_code: foreign_exchange_code
      arb.percent          = percent
      arb.long             = long
      arb.delisted         = delisted
      arb.spb_bid          = spb_bid
      arb.spb_bid_size     = spb_bid_size
      arb.spb_ask          = spb_ask
      arb.spb_ask_size     = spb_ask_size
      arb.foreign_bid      = foreign_bid
      arb.foreign_bid_size = foreign_bid_size
      arb.foreign_ask      = foreign_ask
      arb.foreign_ask_size = foreign_ask_size
      arb.save!
    end
  end

  private def parse_bid_ask_line(line)
    exchange_code, bid_str, ask_str = line.delete('/').squish.split
    bid_price, bid_size = bid_str.split('@')
    bid_price = bid_price.gsub(',', '.').to_f
    bid_size = bid_size.to_i
    ask_price, ask_size = ask_str.split('@')
    ask_price = ask_price.gsub(',', '.').to_f
    ask_size = ask_size.to_i
    [exchange_code, bid_price, bid_size, ask_price, ask_size]
  end
end

__END__
PantiniArbitrageParser.connect 'US'
