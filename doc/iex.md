https://iexcloud.io/docs/api
https://github.com/dblock/iex-ruby-client

curl -s "https://cloud.iexapis.com/stable/stock/FCX/ohlc?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/FCX/splits?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/book?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/clf/insider-roster?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/clf/insider-summary?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/clf/institutional-ownership?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/clf/fund-ownership?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/clf/largest-trades?token=$IEX_SECRET_KEY" | jq 'sort_by(.time)'
curl -s "https://cloud.iexapis.com/stable/stock/yelp/book?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/quote?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/previous?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/ytd?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/date/20210104?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/date/20210104?chartByDay=true&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/date/20210317?chartByDay=true&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/5d?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/delayed-quote?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/intraday-prices?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/options?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/company?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/stats?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/advanced-stats?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/peers?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/volume-by-venue?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/insider-transactions?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/insider-transactions?token=$IEX_SECRET_KEY" > tmp/insiders-AAON.json
curl -s "https://cloud.iexapis.com/stable/stock/aapl/options?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/options/20210618?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/stock/aapl/recommendation-trends?token=$IEX_SECRET_KEY" > cache/iex-ratings/AAPL.json
curl -s "https://cloud.iexapis.com/stable/stock/aapl/estimates?token=$IEX_SECRET_KEY" > cache/iex-estimates/AAPL.json
curl -s "https://cloud.iexapis.com/stable/stock/aapl/price-target?token=$IEX_SECRET_KEY" > cache/iex-price-targets/AAPL.json

curl -s "https://cloud.iexapis.com/stable/futures/ES22M:F/chart?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/futures/ES22M:F/chart?range=1m&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/futures/ES22M:F/chart?from=2022-01-20&token=$IEX_SECRET_KEY" | jq


curl -s "https://cloud.iexapis.com/stable/tops?symbols=aapl,fb,twtr&token=$IEX_SECRET_KEY"
curl -s "https://cloud.iexapis.com/stable/tops?token=$IEX_SECRET_KEY"
curl -s "https://cloud.iexapis.com/stable/tops?token=$IEX_SECRET_KEY" > cache/iex/tops.json
curl -s "https://cloud.iexapis.com/stable/tops?token=$IEX_SECRET_KEY&format=csv" > tmp/tops.csv
curl -s "https://cloud.iexapis.com/stable/data-points/market/GASDESW?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/deep/trades?symbols=CLF&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/deep/book?symbols=yelp&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/options/AAL20210716P00011000/chart?range=1m&token=$IEX_SECRET_KEY" | jq

curl -s "https://cloud.iexapis.com/stable/time-series/CORE_ESTIMATES/FCX?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/time-series/INSIDER_TRANSACTIONS/BH?from=2021-04-01&token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/time-series/INSIDER_TRANSACTIONS/AAPL?from=2021-06-13&token=$IEX_SECRET_KEY" | jq

curl -s "https://cloud.iexapis.com/stable/ref-data/exchange/MIC/symbols?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/ref-data/region/RU/symbols?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/ref-data/options/symbols?token=$IEX_SECRET_KEY" | jq
curl -s "https://cloud.iexapis.com/stable/ref-data/options/symbols/spy?token=$IEX_SECRET_KEY" > tmp/option-dates.json
curl -s "https://cloud.iexapis.com/stable/ref-data/options/symbols/fcx?token=$IEX_SECRET_KEY" > tmp/option-dates-dk.json
curl -s "https://cloud.iexapis.com/stable/ref-data/exchanges?token=$IEX_SECRET_KEY" > tmp/exchanges.json
curl -s "https://cloud.iexapis.com/stable/ref-data/region/DE/symbols?token=$IEX_SECRET_KEY" > tmp/region-DE.json
curl -s "https://cloud.iexapis.com/stable/ref-data/exchange/FRA/symbols?token=$IEX_SECRET_KEY" > tmp/exchange-FRA.json
curl -s "https://cloud.iexapis.com/stable/ref-data/futures/symbols?token=$IEX_SECRET_KEY" > tmp/futures.json
curl -s "https://cloud.iexapis.com/stable/ref-data/futures/symbols/HRC?token=$IEX_SECRET_KEY" > tmp/futures-hrc.json
curl -s "https://cloud.iexapis.com/stable/ref-data/futures/symbols/CL?token=$IEX_SECRET_KEY" > tmp/futures-cl.json
curl -s "https://cloud.iexapis.com/stable/ref-data/futures/symbols/MTF?token=$IEX_SECRET_KEY" > tmp/futures-mtf.json


curl -s "https://sandbox.iexapis.com/stable/stock/aapl/chart/date/20210104?chartByDay=true&token=$IEX_TEST_SECRET_KEY" | jq

# Cost

5.000.000 std credits / mon + 20$ for 20.000.000 premium credits

* analyst recommendation — 1000 (premium)
* 1         RT   /quote
* 2         15m  /ohlc
* 2         EOD  /previous
* 10        15m  /chart
* 1         EOD  /company
* 1         EOD  /logo
* 5         EOD  /stats
* 50 / tx   EOD  /insider-transactions
* 500       EOD  /price-target
* 1000      EOD  /recommendation-trends
* 3000 + 5  EOD  /advanced-stats
* 10000     EOD  /estimates


curl -s "https://cloud.iexapis.com/stable/stock/aapl/chart/1h?token=$IEX_SECRET_KEY" | jq



## Other

https://www.nasdaq.com/market-activity/quotes/nasdaq-ndx-index
https://datahub.io/core/s-and-p-500-companies#resource-constituents

$$(".nasdaq-ndx-index__row th.nasdaq-ndx-index__cell:first-child").map(e => e.innerText)


curl -s "https://cloud.iexapis.com/stable/stock/eqt/insider-roster?token=$IEX_SECRET_KEY" | jq
