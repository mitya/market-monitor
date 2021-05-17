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

- external signals (source, direction, date, price, score)

- custom lists for Oil&Gas / Minerals / Bigtech / Biotech / Tech / Kogan / Elvis / Interesting
- comparisions to random dates


- don't check Europe & Moex2 in the evening
- signal results on close/last prices

- intraday search for more than 1% in 10-min movements
- intraday search for above average volume in 5 min
- intraday accelerations
- intraday alarms

- check tickers with many BUY insider transactions

- search for pull backs
- convert rub-usd based on date
– find stocks with significant spikes last days
– find stocks with strong growth last days
– find stocks with slow growth last days
– find stocks with N% volatility on X previous days and high within Y%
- find stocks with continious flat
- portfolio: add a new ticker from UI
- extract special dates
- indexes & commodities (NUGT SLV)
- tinkoff ticker checking
- disable stocks without any recent data

- russian ticker company info
- maintain average volume for last N months
- ticker selection & commands
- track the first date for tickers (eg ALTO 2021-02-01)
- parse VTB marginal list
- mark Kogan tickers with dates & prices


# Later
– comparision to a random date
- column selection
- terminal-based UI
- charts


onem ddd aten abb abeo abm accd acrx achv acrs acor admp aey acet adnt adma asnd clls kc tlk adt adws ades advm adeyn aer afmd agrx agnc api alrn atsg airfp eadsy akbty akca akba aci alec alks alna alvr aosl amr alt alto altm amrn amba amc axl aep amwl amrs ngloy au abi nly am ar apha apog apo aaoi apre aqms aqst abr mt arch arco asc aaic at1 arry apam asan asx asml asazy atnx aaww team ato attu auo acb athm avdl aveo car axnx ayro azre
