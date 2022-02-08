namespace :id do
  envtask(:sync) { IntradayCandleLoader.new.sync }
  envtask(:load) { IntradayCandleLoader.new.load }
  envtask(:history) { IntradayCandleLoader.new.load_history }
  
  envtask(:check_moex_closings) { IntradayCandleLoader.new.check_moex_closings }
end



__END__
rake id:load tickers='AGRO' period=3 force=1 days=1
rake id:sync tickers='OZON SBER GAZP FIVE MVID' period=3
