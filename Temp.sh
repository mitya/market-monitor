https://github.com/dblock/iex-ruby-client
https://iexcloud.io/docs/api/#insider-transactions

sk_98bc3790c85c45feba2a92de43400934


curl 'https://cloud.iexapis.com/stable/tops?token=sk_98bc3790c85c45feba2a92de43400934&symbols=aapl'
curl 'https://cloud.iexapis.com/stable/stock/aapl/quote?token=sk_98bc3790c85c45feba2a92de43400934'


sk_98bc3790c85c45feba2a92de43400934


curl -sk 'https://cloud.iexapis.com/stable/stock/CERN/insider-transactions?token=sk_98bc3790c85c45feba2a92de43400934' | jq
curl -sk 'https://cloud.iexapis.com/stable//stock/twtr/chart/5d?token=sk_98bc3790c85c45feba2a92de43400934' | jq

GET /stock/{symbol}/previous
