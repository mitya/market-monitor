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
coffee bin/tinkoff.coffee candles BBG000B9XRY4 1min 2022-04-18T00:00:00+03:00 2022-04-18T23:59:00+03:00 | jq
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2021-03-11T00:00:00Z 2021-03-11T00:00:01Z
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2021-03-12T00:00:00Z 2021-03-12T23:59:00Z
coffee bin/tinkoff.coffee candles BBG000B9XRY4 day 2019-01-01T00:00:00Z 2021-03-12T23:59:00Z
coffee bin/tinkoff.coffee candles FUTSBRF06220 day 2022-04-05T00:00:00Z 2022-04-12T00:00:00Z
coffee bin/tinkoff.coffee portfolio

# Images

https://www.tinkoff.ru/invest/stocks?country=Russian&orderType=Asc&sortType=ByName&start=0&end=48
$$('.Avatar-module__image_ZCGVO').map(e => e.style.backgroundImage)
