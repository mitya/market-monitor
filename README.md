https://github.com/dblock/iex-ruby-client
https://iexcloud.io/docs/api/#insider-transactions

sk_98bc3790c85c45feba2a92de43400934


curl 'https://cloud.iexapis.com/stable/tops?token=sk_98bc3790c85c45feba2a92de43400934&symbols=aapl'
curl 'https://cloud.iexapis.com/stable/stock/aapl/quote?token=sk_98bc3790c85c45feba2a92de43400934'


sk_98bc3790c85c45feba2a92de43400934


curl -sk 'https://cloud.iexapis.com/stable/stock/CERN/insider-transactions?token=sk_98bc3790c85c45feba2a92de43400934' | jq
curl -sk 'https://cloud.iexapis.com/stable//stock/twtr/chart/5d?token=sk_98bc3790c85c45feba2a92de43400934' | jq

GET /stock/{symbol}/previous

# Links

* https://github.com/TinkoffCreditSystems/invest-openapi-js-sdk
* https://tinkoffcreditsystems.github.io/invest-openapi/swagger-ui/#/

# Data Sources

    coffee bin/tinkoff.coffee stocks > db/data/stocks.json

    https://spbexchange.ru/ru/listing/securities/list/
    iconv -f CP1251 -t UTF8 db/data/spbex.csv > db/data/spbex-utf.csv
