+ basic tickers database
+ separate spb tickers
+ separate rus & us tickers
- load basic ticker data from IEX
- add ticker lists
- very basic listing UI
- load recommedations from IEX
- load insider trades from IEX
- load EOD data
- find tickers growing 3 days in a row
- ticker dynamics for arbitrary date range


+ tinkoff-import BBG000B9XRY4 1min 2020-10-21T12:02:00+03:00 2020-10-21T13:16:00+03:00
+ create AR record from non-Rails script
+ ruby script to import TI JSON metadata into Postgres

+ ruby script to get candle data for selected tickers using ti-import and store in db
- scheduler to refresh all the data constantly respecting the rate limit (120 rpm)
- terminal-based UI


== Later
- replace node lib with ruby/HTTP
