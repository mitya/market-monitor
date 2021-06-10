+ level hits from below & avove
+ level retests & rebounds
+ colorize level hits

- show more details in chart header (marketcap, trend, price targets)
- alerts

# Next

- improve level rebound search logic
- iex largest trades
- iex International symbols
- search for consolidations
- determine consolidation boundaries
- add breakout dates to rockets
- don't check Europe & Moex2 in the evening
- intraday accelerations
- intraday search for more than 1% in 10-min movements
- intraday search for above average volume in 5 min
- intraday alarms
- custom categories (coal / gas / ...)
- search for pull backs
- convert rub-usd based on date
– find stocks with significant spikes last days
– find stocks with strong growth last days
– find stocks with slow growth last days
– find stocks with N% volatility on X previous days and high within Y%
- find stocks with continious flat
- portfolio: add a new ticker from UI
- extract special dates
- disable stocks without any recent data
- russian ticker company info
- maintain average volume for last N months
- ticker selection & commands


# Later
– comparision to a random date
- column selection
- terminal-based UI


# Done
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
+ load & import today ongoing & yesterday ohlc in one step
+ load current prices in one step
+ colorize last, Topen, Yopen
+ sync available stocks with Tinkoff
+ load IEX ohlc data which is absent of Tinkoff
+ use tickers as foreign keys for candles & prices
+ add Tinkoff premium tickers with ticker info from IEX
+ load old reference candles for premium tickers from IEX
+ load current candles for premium tickers from IEX
+ pagination
+ filters by industry / sector
+ load insider trades from IEX
+ all insider transactions list
+ ticker insider transactions list
+ load price targets from IEX
+ load recommedations from IEX
+ ticker recommendations & price targets list
+ mark premium tickers in the list
+ use radios for currencies & sets
+ filter by premium tickers
+ filter by entered tickers
+ exchange icons
+ show price targets in percents (option)
+ try to use sectors from tops
+ add sector badge to the list
+ extract lists to files
+ filtering by calculated values (maybe right in the code)
+ add poor man sorting
+ 1/2/3 day dynamics
+ add source & last_at to prices
+ indicate that the price is old
+ fix 2 day old candle for premium tickers
+ load opening prices for premium tickers somehow
+ check tickers without any price data
+ try to get european ticker historical data from IEX
+ load advanced stats (forward P/E) for selected tickers from IEX
+ volume indication
+ volatility percentage per day
+ volatility bar indication
+ 2-week volatility chart
+ a set with portfolio tickers
+ number of lots for portfolio set
+ fixed width digits
+ fix table header
+ replace chart API with previous which is cheaper
+ portfolio: convert RUS ticker totals to USD
+ portfolio: sorting by total
+ sets for FallenAngels, Pending
+ missing TEVA ARCH BTU
+ list sorting
+ add current price to the insider transactions list
+ add special dates to aggregates
+ add a way to check which IEX dates are missing
+ sort by clicking a column
+ find stocks growing N days in a row
+ respect US holidays when looking for prev days
+ rename connectors
+ find stocks which hit N-month bottom in last X days and recovered Y %
+ find notable stocks during aggregation + UI
+ show low date as # of days since then
+ UI filter to select those which hit low in recent X days
+ UI filter to select those which gained X..Y since low
+ sorting by lowest date / gain
+ focus tickers filter on load if it it used
+ peers
+ search for external bars
+ download all day candles from IEX
+ add current, buy/sell & stop levels for each signal
+ signal filters by today/yesterday/last 3/last 5
+ highlight outdated price targets
+ make current price relative to Yclose
+ search for pin bars
+ average result for current page of signals by now
+ country flags
+ allow hiding historical prices
+ add last insider buy to info
+ insider buys filter
+ 1h/5m candle loading
+ background loading process (1h, 5m, last)
+ intraday candle analysys, external bars, pinbars
+ intraday signal UI
+ add last insider transaction to aggregate
+ Tinkoff / IIS / VTB / total portfolios
+ load Tinkoff portfolio
+ ideal portfolio
+ external signals (source, direction, date, price, score)
+ mark Kogan tickers with dates & prices
+ indexes & commodities (NUGT SLV)
+ add premium tickers to Tinkoff portfolio
+ parse VTB marginal list
+ show signal results in bars
+ sort signals by current result
+ search for spike-bars
+ in-app charts
+ volume on charts
+ link chart from all pages
+ fix volume chart alignment
+ improve trend days count
+ fix pin bars
+ current row selection
+ custom lists for Bigtech / Biotech / Tech
+ parse gurufocus transactions
+ add gf companies < 500M
+ download april from GF
+ parse SA pages
+ aggregate insider buys into a list with (1/2/3/4m buys/sells)
+ mark tickers with insider buys
+ add score & source filter to public signals
+ Coal list
+ Russia-2 list
+ format list as badges
+ list of rockets
+ 6m insider agregation
+ transportation list
+ consolidations list
+ TRMK.US
+ parallelize candle loading
+ longs terms levels
+ show levels on charts
+ update tinkoff candles to iex
+ add high levels
+ add volume to levels
+ search for long-term level hits
+ level hits listing
+ add a quick way to change ticker on chart
+ track the first date for tickers (eg ALTO 2021-02-01)
+ find & import missing candles
+ add a way to set period on chart
