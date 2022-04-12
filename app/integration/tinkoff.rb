class Tinkoff
  include StaticService

  OutdatedTickers = %w[
    ALXN AORT APY AVP BFYT CHA CHEP CHK CHL CLGX CNST CTB CY DNKN ENPL FLIR FTR FTRE GSH HIIQ LKOD@GS MGNT@GS MINI MNK MQ MSGN NLMK@GS
    NU NVTK@GS OGZD@GS PHOR@GS PLZL@GS PRAH PRSP RUSP SBER@GS SERV SKM SLG SSA@GS SVST@GS TCS TE TOT TSS UTX VIE VZRZP WORK
  ].uniq

  BadTickers = OutdatedTickers

  InstrumentsApi
  OrdersApi
  CandlesApi
  PortfolioApi
  FuturesApi

  private

  def call_js_api(command, parse: true, delay: 0, account: nil)
    command = "coffee bin/tinkoff.coffee #{command}"
    command = "TINKOFF_ACCOUNT=#{account} #{command}" if account
    puts command.purple if $log_tinkoff || ENV['TLOG']
    response = `#{command}`
    sleep delay if delay.to_f > 0
    parse ? JSON.parse(response) : response
  rescue => e
    puts "Error parsing JSON for #{command}".red
    parse ? { } : ''
  end

  def stringify_error(json)
    error_text = "#{json&.dig('error', 'name')} #{json&.dig('error', 'type')}".strip.presence
    error_text || json
  end

  delegate :logger, to: :Rails
end

__END__

Tinkoff.load_candles_to_files('AAPL')
Tinkoff.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 6, 1), till: Date.new(2020, 12, 31))
Tinkoff.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 1, 1), till: Date.new(2020, 12, 31))
Tinkoff.import_latest_day_candles Instrument['PRGS']
Instrument.tinkoff.each { |inst| Tinkoff.import_day_candles inst, since: Date.parse('2019-12-31'), till: Date.parse('2019-12-31').end_of_day }
Instrument.tinkoff.each { |inst| Tinkoff.import_day_candles inst, since: Date.parse('2020-12-31'), till: Date.parse('2020-12-31').end_of_day }

$log_tinkoff = true
Tinkoff.limit_buy 'UPWK', 46.66, 1
Tinkoff.limit_buy 'DK', 1, 17
Tinkoff.cancel_order 283905820350
