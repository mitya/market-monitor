namespace :intraday do
  envtask(:sync) { IntradayLoader.new.sync }
  envtask(:load) { IntradayLoader.new.load }
  envtask(:history) { IntradayLoader.new.load_history }
  
  envtask(:check_moex_closings) { IntradayLoader.new.check_moex_closings }
end



__END__
rake id:load tickers='AGRO' period=3 force=1 days=1
rake id:sync tickers='OZON SBER GAZP FIVE MVID' period=3
