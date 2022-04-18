namespace :intraday do
  envtask(:sync)     { IntradayLoader.sync_charts }
  envtask('sync:ru') { IntradayLoader.sync_ru }
  envtask('sync:us') { IntradayLoader.sync_us }
  envtask(:load)     { IntradayLoader.new.load }
  envtask(:history)  { IntradayLoader.new.load_history }

  envtask(:check_moex_closings) { IntradayLoader.new.check_moex_closings }
end



__END__
rake id:load tickers='AGRO' period=3 force=1 days=1
rake id:sync tickers='OZON SBER GAZP FIVE MVID' period=3
