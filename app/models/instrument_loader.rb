require 'csv'

class InstrumentLoader
  def load_tinkoff_instruments
    data = JSON.parse File.read "db/data/stocks.json"
    Instrument.transaction do
      data['instruments'].sort_by{|h| h['ticker']}.each do |hash|
        next if Instrument.exists? figi: hash['figi']
        puts "Import #{hash['ticker']}"
        Instrument.create! hash.slice(*%w(ticker figi isin lot currency name type lot)).merge(price_step: hash['minPriceIncrement']) do |instr|
          instr.flags = ['ti']
        end
      end
    end
  end

  # Row;s_level_name;e_full_name;e_INN_code;s_sec_type_name_dop;s_sec_form_name_full;s_RTS_code;s_ISIN_code;si_gos_reg_num;si_gos_reg_date;
  #    s_face_value;s_face_value_currency;s_quot_list_in_date;s_segment;s_date_defolt;s_date_technic_defolt
  def load_spb_instruments
    spb_types = { 'Акции' => 'Stock', 'Депозитарные расписки' => 'GDR' }

    CSV.read("db/data/spbex-utf.csv", headers: true, col_sep: ';', quote_char: nil).each do |row|
      row['e_full_name']
      row['s_RTS_code']
      row['s_ISIN_code']
      row['s_sec_type_name_dop'] # Акции 'Депозитарные расписки'
      row['s_face_value_currency'] # USD EUR RUB

      next if row['s_sec_type_name_dop'] != 'Акции'
      next if row['s_face_value_currency'] == 'RUB'
      next if Instrument.exists? ticker: row['s_RTS_code']

      puts "Adding #{row['s_RTS_code']} (#{row['e_full_name']})"

      Instrument.create!(
        ticker: row['s_RTS_code'],
        name: row['e_full_name'],
        isin: row['s_ISIN_code'],
        currency: row['s_face_value_currency'],
        type: spb_types[row['s_sec_type_name_dop']],
        flags: ['spb'],
      )
    end
  end

  def load_candles(tickers = TICKERS)
    tickers.each do |ticker|
      puts "Load #{ticker}..."
      load_candle ticker, '5min', 20.minutes.ago, Time.current
      sleep 1
    end
  end

  def load_candle(ticker, interval, since, till)
    instrument = Instrument.find_by(ticker: ticker)
    if Candle.where(figi: instrument.figi, interval: interval).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?()
      puts "Skip #{ticker.ljust 6}"
      return true
    end

    puts "Load #{ticker.ljust 6} #{interval} candles for #{since} - #{till}"
    json = `coffee test.coffee candles #{instrument.figi} #{interval} #{since.xmlschema} #{till.xmlschema}`
    data = JSON.parse json

    data['candles'].each do |hash|
      Candle.find_or_create_by! figi: instrument.figi, interval: hash['interval'], time: Time.parse(hash['time']) do |candle|
        candle.open     = hash['o']
        candle.close    = hash['c']
        candle.high     = hash['h']
        candle.low      = hash['l']
        candle.volume   = hash['v']
      end
    end

    return false
  end

  def load_day_candles
    Instrument.pluck(:ticker).each do |ticker|
      already_loaded = load_candle ticker, 'day', 1.week.ago, Time.current
      sleep 0.25 unless already_loaded
    end
  end

  class << self
    def method_missing(method, *args)
      new.send(method, *args)
    end
  end
end

__END__

Instrument.delete_all
rr 'InstrumentLoader.load_tinkoff_instruments'
rr 'InstrumentLoader.load_spb_instruments'
Candle.where(figi: Instrument.find_by(ticker: 'AAPL').figi, interval: 'day').where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?
