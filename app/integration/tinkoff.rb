class Tinkoff
  include StaticService

  OutdatedTickers = %w[
    NVTK@GS LKOD@GS OGZD@GS NLMK@GS PHOR@GS SBER@GS SVST@GS SSA@GS MGNT@GS PLZL@GS
    AGN AIMT AOBC APY AVP AXE BEAT BFYT BMCH CHA CHL CXO CY DLPH DNKN ENPL ETFC FTRE HDS HIIQ IMMU LM LOGM LVGO MINI MYL
    MYOK NBL PRSC PRTK RUSP SERV SINA TECD TIF TRCN TSS UTX VAR VRTU WYND ACIA FLIR EV PLT PS VIE CBPO MTSC PRSP RP MQ TE
    MNK GSH FTR CTB TOT VZRZP ALNU TCS CLGX MSGN WORK PRAH KBTK HOME LMNX CCIV ALXN CLNY GTT CNST LB TLND SYKE PFPT QTS
    CHK CREE CSOD GRA QADA STMP XEC CLDR ECHO XLRN CHEP COR DRNA KSU MGLN RDS.A SLG AORT NU SKM AKBTY CCHGY
  ].uniq

  BadTickers = OutdatedTickers
  
  InstrumentsApi
  OrdersApi
  CandlesApi
  PortfolioApi

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
