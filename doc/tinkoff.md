# Links

* https://github.com/Tinkoff/invest-openapi
* https://github.com/TinkoffCreditSystems/invest-openapi-js-sdk
* https://tinkoffcreditsystems.github.io/invest-openapi/swagger-ui/#/
* https://tinkoff.github.io/investAPI/swagger-ui/#

* https://www.tinkoff.ru/invest/margin/equities/

# Rate limits

/market — 240 / min

# Commands

coffee bin/tinkoff.coffee candles BBG000B9XRY4 5min 2021-05-10T18:20:00+03:00 2021-05-10T18:30:00+03:00 | jq

coffee bin/tinkoff.coffee candles BBG000QX74T1 5min 2021-05-10T18:20:00+03:00 2021-05-10T18:30:00+03:00 | jq

coffee bin/tinkoff.coffee candles BBG000B9XRY4 5min 2020-10-21T12:02:00+03:00 2020-10-21T13:16:00+03:00
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2021-03-11T00:00:00Z 2021-03-11T00:00:01Z
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2021-03-12T00:00:00Z 2021-03-12T23:59:00Z
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2019-01-01T00:00:00Z 2021-03-12T23:59:00Z
coffee bin/tinkoff.coffee candles FUTSBRF06220 day 2022-04-05T00:00:00Z 2022-04-12T00:00:00Z
coffee bin/tinkoff.coffee portfolio

# Images

https://www.tinkoff.ru/invest/stocks?country=Russian&orderType=Asc&sortType=ByName&start=0&end=48

$$('.Avatar-module__image_ZCGVO').map(e => e.style.backgroundImage)




curl -X POST 'https://invest-public-api.tinkoff.ru/rest/tinkoff.public.invest.api.contract.v1.InstrumentsService/Futures' \
  -H 'accept: application/json' -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer t.OWfz5cjTldyoEAgzYqbsemeF6ckc8C5AGXg-itWIWNy_kUZDcMlsmrEDcXGOic-_vZTTV1lsUiBU_qXK9FnLhA' \
  -d '{ "instrumentStatus": "INSTRUMENT_STATUS_UNSPECIFIED" }' > tmp/v2-futures.json


curl -X 'POST' \
  'https://invest-public-api.tinkoff.ru/rest/tinkoff.public.invest.api.contract.v1.MarketDataService/GetCandles' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer t.OWfz5cjTldyoEAgzYqbsemeF6ckc8C5AGXg-itWIWNy_kUZDcMlsmrEDcXGOic-_vZTTV1lsUiBU_qXK9FnLhA' \
  -H 'Content-Type: application/json' \
  -d '{
  "figi": "FUTMAIL06220",
  "from": "2022-04-12T07:00:00.002Z",
  "to": "2022-04-12T17:00:00.002Z",
  "interval": "CANDLE_INTERVAL_1_MIN"
}'
