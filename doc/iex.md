https://github.com/dblock/iex-ruby-client
https://iexcloud.io/docs/api/#insider-transactions


curl -s "https://cloud.iexapis.com/stable/stock/aapl/quote?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/delayed-quote?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/last?symbols=aapl&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/options?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/company?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/stats?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/advanced-stats?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/peers?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/volume-by-venue?token=$IEX_SECRET_KEY" | jq

curl -sk 'https://cloud.iexapis.com/stable/stock/CERN/insider-transactions?token=sk_98bc3790c85c45feba2a92de43400934' | jq
curl -sk 'https://cloud.iexapis.com/stable//stock/twtr/chart/5d?token=sk_98bc3790c85c45feba2a92de43400934' | jq


# Cost

5.000.000 std credits / mon + 20$ for 20.000.000 premium credits

* analyst recommendation — 1000 (premium)
* 1         RT   /quote
* 2         15m  /ohlc
* 1         EOD  /company
* 1         EOD  /logo
* 5         EOD  /stats
* 50 / tx   EOD  /insider-transactions
* 3000 + 5  EOD  /advanced-stats
* 1000      EOD  /recommendation-trends
* 10000     EOD  /estimates
* 500       EOD  /price-target
