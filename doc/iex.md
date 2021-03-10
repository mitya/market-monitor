https://github.com/dblock/iex-ruby-client
https://iexcloud.io/docs/api/#insider-transactions


curl -s "https://cloud.iexapis.com/stable/stock/aapl/quote?token=$IEX_SECRET_KEY"
curl -s "https://cloud.iexapis.com/stable/last?symbols=aapl&token=$IEX_SECRET_KEY"
curl -s "https://cloud.iexapis.com/stable/stock/aapl/options?token=$IEX_SECRET_KEY"

curl -sk 'https://cloud.iexapis.com/stable/stock/CERN/insider-transactions?token=sk_98bc3790c85c45feba2a92de43400934' | jq
curl -sk 'https://cloud.iexapis.com/stable//stock/twtr/chart/5d?token=sk_98bc3790c85c45feba2a92de43400934' | jq


# Cost

5.000.000 std credits / mon + 20$ for 20.000.000 premium credits

* analyst recommendation — 1000 (premium)
* quote — 1
* ohlc — 2
* insider transactions — 50 / tx
