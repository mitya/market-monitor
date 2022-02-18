- add a way to set a list on the dash as current

- dashboard with distances to highs / lows + dashboard with new highs / new lows
- turn-around scanner (+5% today, open is 20% lower than any point in last 5 sessions, 150%+ volume)

- run empty analysis & mark candles
- hits for today open in 15+ mins since start, then only after 4% change
- hits yesterday close
- hits for yesterday/today HOD / LOD
- hits for DMA
- hits for predefined levels
- list of intraday scans
- long shadows (espesially with volume)
- volume spikes
- volume minimizations
- HOD retest when high > 2% && low since high < -2%
- HOD 2%+ open down break
- 4% fall — first green 3m bar, min 0.4%
- show intraday scans on the chart
- show scan ticker in the next available intraday chart

# Next
- page with 1 chart and a list of tickers to quickly check it out
- dash for changes in last N mins
- expected MA hits analysis
- save MA data for some recent date
- fully automate multiple missing days loading
- inject fake candles when ticker with different start times are shown
- use dropdown for sets
- search for stable tops / bottoms
- list all the institutional holders & find last quarter institutional transactions
- modal with L2 and buy / sell buttons
- once a day set price to last for tickers without the IEX price data
- 5-min morning data & fill gaps in 5m candles
- show price targets on arb page
- arb list non-jerky refresh
- show correction since 6-m high and gains since after-high low
- highlight signalled tickers in SPB list
- compare Tinkoff highs / lows with IEX
- compare Tinkoff 11:00 prices with day highs on IEX
- check yesterday close vol/change corellation with the next day
- find large call options blocks with prices significantly higher than the current
- find the call / put balance point
- find significant call / put differences when the option buyer seem to be making money
- 2% over yesterday high signals
- insider buy signals
- search for period lows / highs (e.g. 1w)
- calculate average change from low-to-high
- institutional ownership UI
- analyze large moves (from flat and from prior slow move)
- analyze shelves
- indexes state bar & index updates
- constant price update process for TI
- new chart engine
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
- change insider transactions to new API with `from` parameter
– comparision to a random date
- column selection
- terminal-based UI
- store the already loaded intraday dates for each interval (perf text vs close check)
- a row with indexes / commodity futures [needs intraday futures data]
- inject missing intraday candles
- refactor JS
- Ruby 3.1
- Rails 7


# Bugs
- volume losers don't look correct
- some days since last MA hit don't look correct


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
+ level hits from below & avove
+ level retests & rebounds
+ colorize level hits
+ show more details in chart header (marketcap, trend, price targets)
+ manual levels
+ export list as TV file
+ import TV list
+ perf comparision chart in period
+ show portfolio without weights
+ colorize sets
+ add sets to insider tx page
+ intraday 1-min prices
+ iex insider summaries
+ institutional ownership & major insiders
+ show current TI prices for outside candles & highligh those which are good to enter (-1.5%)
+ signal results
+ signal results UI
+ aggregate & analyze dates YTD
+ breakout signals
+ negative breakouts signals
+ signal permutation analyzer
+ aggregate results with date range
+ signal prev month dynamics
+ signal volume / avg volume
+ signal on level
+ show volume / level in UI
+ check volume & level corellation in strategies
+ page with all SPB price anomalities (Y close, Y change, Ti last, Ti 1h min, Ti 1h vol)
+ load last 2 5m candles from IEX &
+ load all Tinkoff USD candles
+ load options data
+ load IEX transactions via date ranged feed
+ rake task for options
+ options straddle table
+ options history table
+ install Pantini extension & check out the order log
+ show volume changes in the main list
+ show L2 on arb page
+ group foreign exchanges by ticker
+ refresh the arb list with a button
+ sync orders
+ show orders list
+ show operations
+ 5-min overview page
+ orders / operations / portfolio page
+ show portfolio
+ 5 min accumulation bar chart
+ the ask Buy button
+ move buy/sell indication to best bid/ask
+ format arb table in one line
+ indicate average price in portfolio
+ order cancellation button
+ activity page refresh
+ overview page with known tickers grouped by industry
+ calculate MA and watch for MA passing
+ today gainers / losers
+ find extremums
+ add ability to add new special dates
+ search for 4% spikes
+ show daily/weekly trading vol in money
+ improve Rus illiquid stocks list
+ improve the menu
+ add NASDAQ 100 & S&P 500 companies
+ TV chart programming - open/close lines
+ fix diff to year begins
+ fix 200 MA
+ show % & days since 52w high
+ load splits
+ add russian companies info & market cap
+ filter field for MA50/200
+ predefined links for MA analysis
+ tinkoff marginal list
+ add news parser
+ fix trend indicators
+ search for MA retests
+ search for custom level retest
+ show all recent dates in the hits list
+ break / test depth
+ hit continuation check
+ recalculate MA200s (load 2018)
+ show margin factors
+ show hits for single ticker
+ custom level import
+ compile the Known list & categorize everything in it
+ compare gains since random date
+ 3m & 1y comparisions
+ news UI
+ news sync process
+ add prev candle close to each daily candle
+ calc ATRs
+ intraday candle loader
+ run analyze each time a candle is loaded
+ load 3m candles
+ look for simplest things — .5% moves
+ look for .5 moves in 2 candles
+ show volume as marketcap %
+ for MA retests / breakouts add days since last cross
+ for MA breakouts add relvol & o-c change
+ sets dashboard
+ data field selection / sorting
+ show multiple sets in 1 column
+ filter sets by tickers
+ filter sets by currency / premium
+ filter form hiding
+ load tops as csv
+ send ws notification when the prices are updated
+ listen for 'reload' notification on the UI side
+ change maps
+ intraday chart
+ multiple intraday charts on screen
+ load all recent intraday candles for tickers
+ realtime load intraday market data for tickers
+ data pull to the browser
+ chart period change
+ dash for top gain / loss, same in RU, my US / RU tickers change
+ dash changes as bars
+ mine / watch us / watch ru column on dashboard
+ price update process
+ mark day opens
+ DMA lines on intraday charts
+ reload dashboard on price update only if sorted by today price
+ open/close lines on intraday charts
+ custom levels on charts +editor
+ ticker sets editor
+ ticker sets list near charts
+ identify non-liquid RUS tickers
+ mark OTC / non-liquid tickers on dashboard
+ list changes in ATRs
+ store/show the last update timestamp
+ catch new sync tickers without the process restart (pull db every second)
+ reload charts after period/tickers/levels change
+ chart columns selector + daily / 1h on-chart vertical comparisions
+ mark opening intraday candles
+ increase the chart scale
+ add buttons to inc/dec prices scale
+ load the timeframe used on chart (Mx)
+ go to realtime button
+ scales togglers
+ option to disable ticker set sync
+ ajax buttons to trigger IEX / T price updates
+ check why some tickers are loading after the EOD
+ show last bar price in chart header
+ 100 MA data & recalc others
+ move ticker sets to a combo box
+ load far history after today loading
+ show % change since open in legend
+ show candle time in legend
+ calculate charts height
+ full screen mode
+ remember chart scales
+ mark ongoing intraday candles
+ dash for MA hits
+ quick currency / source selectors for dashboards (in summary)
+ show rel vol & days since last for MA dash
+ volume gainers/losers dash
+ spikes dash
+ level hits dash
+ extract static level / level hit logic into services
+ manual levels dash
+ KSPI & SPBE changes ??
+ buttons to go page down/up
+ toggles for scroll scaling, levels, level labels
+ rebuild all MA hits
+ move chart prefs to a modal
+ row count selector in toolbar
+ single ticker chart mode + list of tickers
+ mark current ticker in the list
+ add keyboard navigation to tickers list