class Tinkoff
  concerning :FuturesApi do

    API_BASE = "https://invest-public-api.tinkoff.ru/rest/tinkoff.public.invest.api.contract.v1"
    API_TOKEN = ENV['TINKOFF_PROD_TOKEN']
    API_HEADERS = { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{API_TOKEN}" }

    API_V2_INTERVALS = {
      '1min'  => 'CANDLE_INTERVAL_1_MIN',
      '5min'  => 'CANDLE_INTERVAL_5_MIN',
      '15min' => 'CANDLE_INTERVAL_15_MIN',
      'hour'  => 'CANDLE_INTERVAL_HOUR',
      'day'   => 'CANDLE_INTERVAL_DAY',
    }

    def request_v2_api(endpoint, params)
      response = RestClient.post "#{API_BASE}.#{endpoint}", params.to_json, API_HEADERS
      JSON.parse response.body
    end

    def get_v2_stocks
      data = request_v2_api "InstrumentsService/Shares", { "instrumentStatus": "INSTRUMENT_STATUS_UNSPECIFIED" }
    end

    def get_v2_futures
      data = request_v2_api "InstrumentsService/Futures", { "instrumentStatus": "INSTRUMENT_STATUS_UNSPECIFIED" }
      File.write "db/data/tinkoff-futures.json", data.force_encoding("UTF-8")
    end

    def import_futures
      moex_stock_tickers = Instrument.active.rub.pluck(:ticker).to_set
      futures = JSON.parse File.read("db/data/tinkoff-futures.json"), object_class: OpenStruct
      futures = futures.instruments
      futures = futures.select { moex_stock_tickers.include? _1.basicAsset }
      futures = futures.reject { _1.expirationDate.to_time.past? }
      futures = futures.sort_by &:ticker
      futures.each do |future|
        instrument = Instrument.find_or_create_by ticker: future.ticker, type: 'Future' do |record|
          record.figi     = future.figi
          record.currency = future.currency.upcase
          record.name     = future.name
          record.lot      = future.lot
          record.exchange = future.exchange
          record.flags    = ['tinkoff']
        end
        Future.find_or_create_by ticker: future.ticker do |record|
          record.base_ticker     = future.basicAsset
          record.base_lot        = future.basicAssetSize.units
          record.expiration_date = future.expirationDate
        end
      end
    end

    def import_intraday_candles_v2(instrument, interval, since: nil, till: nil)
      since ||= instrument.candles_for(interval).today.last&.datetime || Date.current
      till  ||= since.end_of_day

      data = request_v2_api 'MarketDataService/GetCandles', figi: instrument.figi, from: since.xmlschema, to: till.xmlschema, interval: API_V2_INTERVALS[interval]
      sleep 0.1
      import_v2_candles data, instrument, interval
    end

    def import_v2_candles(data, instrument, interval)
      candles = data['candles'].to_a
      candle_class ||= Candle.interval_class_for(interval)

      candle_class.transaction do
        candles = candles.sort_by { _1['time' ]}
        candles.map do |hash|
          timestamp = Time.parse(hash['time']).in_time_zone(instrument.time_zone)
          date = timestamp.to_date
          hhmm = timestamp.to_s(:time)
          ongoing = !hash['isComplete']

          params = { ticker: instrument, date: date }
          params.merge! time: hhmm if candle_class.intraday?
          candle = candle_class.find_or_initialize_by(params)
          puts "Import Tinkoff V2 #{date} #{hhmm} #{interval} #{instrument} #{ongoing ? '...' : ''}".colorize(candle.new_record?? :green : :yellow)

          candle.ticker  = instrument.ticker
          candle.source  = 'tinkoff'
          candle.open    = hash['open']['units']
          candle.close   = hash['close']['units']
          candle.high    = hash['high']['units']
          candle.low     = hash['low']['units']
          candle.volume  = hash['volume']
          candle.date    = date
          candle.ongoing = ongoing

          candle.save!
          candle
        end
      end
    end
  end
end


__END__

Tinkoff.import_futures
Instrument.futures.rub.each { |inst| Tinkoff.import_intraday_candles_v2 inst, '1min' }
Price.sync_with_last_candles Instrument.futures.rub

instr('YNM2').candles_for('1min').today.last&.datetime
