class Tinkoff
  concerning :InstrumentsApi do
    def sync_instruments(preview: true)
      file = Pathname("db/data/tinkoff-stocks.json")
      file.write `coffee bin/tinkoff.coffee stocks` # unless file.exist?

      data = JSON.parse file.read
      problematic_tickers = []
      new_tickers = []
      instruments = data['instruments'].reject { |hash| hash['ticker'].include?('old') }

      instruments.each do |hash|
        if inst = Instrument.find_by_ticker(hash['ticker'])
          if inst.isin != hash['isin']
            puts "Diff ISIN - #{inst.ticker} - #{hash['name']} (was #{inst.name})".yellow
            problematic_tickers << inst.ticker
          end
          if inst.figi != hash['figi']
            puts "Diff FIGI - #{inst.ticker} - #{hash['name']} (was #{inst.name})".yellow
            problematic_tickers << inst.ticker
          end
          if inst.premium?
            puts "#{inst.ticker} is on SPB now".magenta
          end
        else
          next if BadTickers.include?(hash['ticker'])
          puts "Miss #{hash['ticker']} - #{hash['name']}".green
          new_tickers << hash['ticker']
        end
      end

      current_tickers = instruments.map { |hash| hash['ticker'] }.to_set
      outdated_tickers = Instrument.tinkoff.stocks.reject { |inst| inst.ticker.in? current_tickers }
      puts
      puts "Outdated: #{outdated_tickers.map(&:ticker).sort.join(' ')}"
      puts "Problematic: #{problematic_tickers.sort.join(' ')}"
      puts "New: #{new_tickers.sort.join(' ')}"
      puts

      first_dates = YAML.load_file("db/data/first-dates.yaml")

      unless preview
        instruments.
          select { |hash| new_tickers.include? hash['ticker'] }.
          each do |hash|
            puts "Create #{hash['ticker']}"
            inst = Instrument.create! instrument_attrs_from(hash)
            if first_date = first_dates[hash['ticker']]
              inst.update! first_date: first_date
            end
          end

        instruments.
          select { |hash| problematic_tickers.include? hash['ticker'] }.
          each do |hash|
            puts "Update #{hash['ticker']}"
            inst = Instrument.get(hash['ticker'])
            inst.candles.delete_all
            inst.price&.destroy
            inst.update! instrument_attrs_from(hash)
          end
      end
    end

    def instrument_attrs_from(hash)
      hash.slice(*%w(ticker figi isin lot currency name type lot)).merge(
        price_step: hash['minPriceIncrement'],
        flags: ['tinkoff'],
      )
    end

    def import_instruments
      data = JSON.parse File.read "db/data/stocks.json"
      Instrument.transaction do
        data['instruments'].sort_by{|h| h['ticker']}.each do |hash|
          next if Instrument.exists? figi: hash['figi']
          next if hash['ticker'].include?('old')
          puts "Import #{hash['ticker']}"
          Instrument.create! instrument_attrs_from(hash)
        end
      end
    end

    def import_currencies
      data = JSON.parse File.read "db/data/currencies.json"
      tickers_map = {
        'EUR_RUB__TOM' => 'EUR_RUB',
        'USD000UTSTOM' => 'USD_RUB',
      }
      Instrument.transaction do
        data['instruments'].sort_by{|h| h['ticker']}.each do |hash|
          next unless hash['ticker'].in? %w[EUR_RUB__TOM USD000UTSTOM]
          next if Instrument.exists? figi: hash['figi']
          puts "Import #{hash['ticker']}"
          Instrument.create!(
            ticker: tickers_map[hash['ticker']],
            exchange: 'MOEX',
            **hash.slice(*%w(figi lot currency name type lot)).merge(
              price_step: hash['minPriceIncrement'],
              flags: ['tinkoff'],
            )
          )
        end
      end
    end

    def check_dead_instruments
      file = Pathname("db/data/tinkoff-stocks.json")
      data = JSON.parse file.read
      index = data['instruments'].map { _1['ticker'] }.to_set
      removed_tickers_which_are_still_in_tinkoff = Tinkoff::OutdatedTickers.select { index.include? _1 }
      puts removed_tickers_which_are_still_in_tinkoff.sort.join(' ')
    end
  end
end
