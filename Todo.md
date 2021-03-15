+ tinkoff-import BBG000B9XRY4 1min 2020-10-21T12:02:00+03:00 2020-10-21T13:16:00+03:00
+ create AR record from non-Rails script
+ ruby script to import TI JSON metadata into Postgres
+ ruby script to get candle data for selected tickers using ti-import and store in db
+ basic tickers database
+ separate spb tickers
+ separate rus & us tickers
+ load day candles from Tinkoff to files
+ load day candles from files to db
+ very basic listing UI
+ task to load all missing days ohlc data from Tinkoff
+ last, open, close, open %, 1w %, 1m %, jan1 %, nov9%, mar23%, bc%
+ load logos from IEX
+ current price loading from Tinkoff
+ symbol lists model
+ symbol lists in UI
+ candle preloading for selected symbols & dates
+ rus logos
+ fix comparisons
+ load ticker data from IEX

- load & import today ongoing & yesterday ohlc in one step
- load current prices in one step
– find stocks growing N days in a row

- extract special dates
- recurring current price loading
- recurring day candle loading
- recurring 5-min candles loading
– daily ohlc data load, import & aggregation

– load insider trades from IEX
– load recommedation trends, estimates & price targets from IEX
– load daily ohlc from IEX
– load current prices in batches from IEX
- load advanced stats (forward P/E) from IEX

- insider transactions list
– find stocks with N% volatility on X previous days and high within Y%
– find stocks with significant spikes last days

- company extended info list
– data aggregation into a table
- fixed width digits
- indexes & commodities

# Later
– comparision to a random date
- column selection
- terminal-based UI
