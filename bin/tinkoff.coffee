# coffee bin/tinkoff.coffee stocks > db/data/stocks.json
# coffee bin/tinkoff.coffee candles BBG000B9XRY4 5min 2020-10-21T12:02:00+03:00 2020-10-21T13:16:00+03:00

OpenAPI = require '@tinkoff/invest-openapi-js-sdk'

commandArguments = process.argv.slice(2)
[command, figi, interval, since, till] = commandArguments

log = (object) -> console.log object
print = (object) -> console.log JSON.stringify(object, null, 2)
printError = (object) -> console.warn JSON.stringify(object, null, 2)

do ->
  try
    api = new OpenAPI {
      apiURL: 'https://api-invest.tinkoff.ru/openapi/sandbox/' # 'https://api-invest.tinkoff.ru/openapi'
      socketURL: 'wss://api-invest.tinkoff.ru/openapi/md/v1/md-openapi/ws'
      secretToken: process.env.TINKOFF_TEST_TOKEN
    }
    await api.sandboxClear()

    switch command
      when 'stocks'     then print await api.stocks()
      when 'etfs'       then print await api.etfs()
      when 'bonds'      then print await api.bonds()
      when 'currencies' then print await api.currencies()
      when 'search'     then print await api.search(ticker: 'MSFT')
      when 'candles'    then print await api.candlesGet({ figi, interval, from: since, to: till })

  catch error
    print { error }



# console.log(marketInstrument)
# console.log(await api.instrumentPortfolio({ figi })); // В портфеле ничего нет
# console.log(await api.orderbookGet({ figi })); // получаем стакан по AAPL
# api.orderbook({ figi, depth: 10 }, (x) => {
#   console.log(x.bids);
# });
# api.candle({ figi }, (x) => {
#   console.log(x.h);
# });
