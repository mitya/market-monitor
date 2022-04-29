import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'
import { Modal } from 'bootstrap'
import _ from 'lodash'


currentBarSpacing = 2
chartHeight = 0
isOneChartPerPage = false
singleMode = false
isDaily = false
isZeroScale = false

levelColors =     { MA20: 'blue',    MA50: 'green',   MA100: 'orange', MA200: 'red',     open: 'orange',  close: 'orange',   intraday: 'gray'  , swing: 'black' }
levelLineStyles = { MA20: 'Dashed',  MA50: 'Dashed',  MA100: 'Solid',   MA200: 'Dashed',   open: 'Solid', close: 'Dotted',  intraday: 'Dotted', swing: 'Solid'}
levelLineWidths = { MA20: 2,         MA50: 2,         MA100: 2,         MA200: 2,         open: 2,        close: 2,         intraday: 2       , swing: 1      }



export default class Chart
  @prop 'legend', -> @container.querySelector('.intraday-chart-legend')

  # { ticker, candles, opens, levels, timeScaleVisible, priceScaleVisible, wheelScaling, levelLabelsVisible, levelsVisible, rows }
  constructor: (data) ->
    @data = data
    @ticker = data.ticker
    @period = data.period

    # timestamps = data.candles.map((c) -> c[0])
    # console.log timestamps.length
    # console.log _.uniq(timestamps).length
    # data.candles = data.candles[0..200]

    @root = document.querySelector('.intraday-charts')

    currentBarSpacing  = parseInt(@root.dataset.barSpacing)
    currentRowsPerPage = parseInt(@root.dataset.rows)
    currentColsPerPage = parseInt(@root.dataset.cols)
    isOneChartPerPage = currentRowsPerPage == 1 && currentColsPerPage == 1
    singleMode = $qs('.chart-tickers-list') != null || isOneChartPerPage
    isDaily = @period == 'day'

    if singleMode
      @data.timeScaleVisible = true
      @data.priceScaleVisible = true

    @root.insertAdjacentHTML('beforeend', "
      <div class='intraday-chart col #{if singleMode then '' else 'py-1'}' data-ticker='#{@ticker}'>
        <div class='intraday-chart-content'>
          <div class='intraday-chart-legend'>
            <span class='chart-ticker'></span>
            <span class='candle-price'></span>
            <span class='candle-time px-1'></span>
            <span class='change-percent'></span>
            <span class='candle-average' data-period='20'  style='color: #{levelColors['MA20']}'></span>
            <span class='candle-average' data-period='50'  style='color: #{levelColors['MA50']}'></span>
            <span class='candle-average' data-period='100' style='color: #{levelColors['MA100']}'></span>
            <span class='candle-average' data-period='200' style='color: #{levelColors['MA200']}'></span>
          </div>
        </div>
      </div>
    ")

    @container = @root.lastChild

    navbarHeight = 0 # document.querySelector('.main-navbar').offsetHeight
    toolbarHeight = document.querySelector('.trading-toolbar').offsetHeight + 8
    chartContainerHeight = window.innerHeight - navbarHeight - toolbarHeight
    chartHeight = (chartContainerHeight - 4 * 2 * currentRowsPerPage) / currentRowsPerPage

    interval = $qs(".trading-page [name=interval]").dataset.buttonGroupCurrentValue
    isZeroScale = isOneChartPerPage && interval == 'day'

    @chart = createChart @container.querySelector('.intraday-chart-content'), {
      width: 0
      height: chartHeight
      timeScale:
        timeVisible: true
        secondsVisible: false
        visible: @data.timeScaleVisible
        barSpacing: currentBarSpacing
        rightOffset: if singleMode || isOneChartPerPage then 10 else 0
      rightPriceScale:
        entireTextOnly: true
        visible: @data.priceScaleVisible
        mode: PriceScaleMode.Normal # Percentage IndexedTo100
        autoScale: true
        borderVisible: false
        scaleMargins:
          top: 0.02
          bottom: if isZeroScale then 0.0 else 0.05
      localization:
        priceFormatter: formatPrice
      grid:
        horzLines:
          visible: @data.priceScaleVisible
        vertLines:
          visible: true
      handleScale:
        axisPressedMouseMove: true
        mouseWheel: @data.wheelScaling
      handleScroll: true
      priceScaleId: 'right'
      crosshair: { mode: CrosshairMode.Normal }
    }
    @chart.subscribeCrosshairMove @onCrosshairMove

    candlesData = @data.candles.map dataRowToCandle
    @loadedHigh = _.maxBy(candlesData, 'high')?.high
    @loadedLow = _.minBy(candlesData, 'low')?.low

    @lastCandle = candlesData[candlesData.length - 1]


    if singleMode && isDaily && @loadedHigh && @loadedLow
      @autoscaleInfoProvider = => { priceRange: { minValue: (if isZeroScale then 0 else @loadedLow), maxValue: @loadedHigh } }
    else
      @autoscaleInfoProvider = (original) =>
        res = original()
        res.priceRange.minValue = Math.min(res.priceRange.maxValue * 0.95, res.priceRange.minValue)
        res.priceRange.minValue = 0 if isZeroScale && res
        res

    @candlesSeries = @chart.addCandlestickSeries(
      autoscaleInfoProvider: @autoscaleInfoProvider
      # autoscaleInfoProvider: -> { priceRange: { minValue: 0, maxValue: 80 },  margins: { above: 50, below: 50 } }
    )
    @candlesSeries.setData candlesData

    volumeData  = @data.candles.map dataRowToVolume
    @volumeSeries = @chart.addHistogramSeries
      priceFormat:
        type: 'volume'
      priceLineVisible: false
      lastValueVisible: false
      color: 'rgba(76, 76, 76, 0.3)'
      priceScaleId: 'volume'
      scaleMargins:
        top: 0.85
        bottom: 0
    @volumeSeries.setData volumeData

    @legend.querySelector('.chart-ticker').innerText = @ticker
    @setLegendFromCandle @lastCandle

    @setupOpenMarkers() if @data.opens
    @setupLevelLines()  if @data.levelsVisible


  onCrosshairMove: (param) =>
    if param.time
      candle = Array.from( param.seriesPrices.values() )[0]
      @setLegendFromCandle { ...candle, time: param.time, context: param }
    else
      @setLegendFromCandle @lastCandle

  setLegendFromCandle: (candle) =>
    legend = @legend
    changeBox = legend.querySelector('.change-percent')
    averagesBox = legend.querySelector('.candle-averages')
    if candle
      formattedPrice = candle.close.toFixed(2)
      formattedTime = if isDaily then formatDate(candle.time) else formatTime(candle.time - 3 * 60 * 60)
      legend.querySelector('.candle-time').innerText = formattedTime
      legend.querySelector('.candle-price').innerText = formattedPrice
      legend.querySelector(".candle-average[data-period='20']").innerText = ''
      legend.querySelector(".candle-average[data-period='50']").innerText = ''
      legend.querySelector(".candle-average[data-period='100']").innerText = ''
      legend.querySelector(".candle-average[data-period='200']").innerText = ''

      if openPrice = @data.levels.open
        changeSinceOpen = candle.close - openPrice
        percentage = changeSinceOpen / openPrice
        formattedChange = (percentage * 100).toFixed(1) + '%'
        changeBox.innerText = formattedChange
        if percentage > 0
          changeBox.classList.add('is-green')
          changeBox.classList.remove('is-red')
        else
          changeBox.classList.add('is-red')
          changeBox.classList.remove('is-green')

      if @averageSeries && candle.context
        for period, series of @averageSeries
          average = candle.context.seriesPrices.get(series)
          legend.querySelector(".candle-average[data-period='#{period}']").innerText = formatPrice average

    else
      legend.querySelector('.candle-time').innerText = ''
      legend.querySelector('.candle-price').innerText = ''
      changeBox.innerText = ''


  setupOpenMarkers: ->
    @candlesSeries.setMarkers @data.opens.map (openingTime) ->
      { time: openingTime, position: 'aboveBar', color: 'orange', shape: 'circle', text: 'O' }

    # chart.timeScale().fitContent()
    # lineSeries.setMarkers [ # circle arrowDown arrowUp
    #   { time: candlesData[candlesData.length - 10].time, position: 'aboveBar', color: 'red', shape: 'arrowDown', text: '2Top' },
    #   { time: candlesData[candlesData.length - 20].time, position: 'belowBar', color: 'green', shape: 'arrowUp', text: 'Level' },
    # ]


  setupLevelLines: ->
    if @data.averages
      @averageSeries = {}
      for period of @data.averages
        @averageSeries[period] = @chart.addLineSeries
          color: levelColors["MA#{period}"]
          lineWidth: 2
          priceScaleId: 'right'
          priceLineVisible: false
          autoscaleInfoProvider: @autoscaleInfoProvider
        @averageSeries[period].setData @data.averages[period].map  (row) -> { time: row[0], value: Number(row[1]) }

    for title, values of @data.levels
      continue if values == null
      values = [values] unless values instanceof Array
      for level in values
        @candlesSeries.createPriceLine
          price: Number(level)
          color: levelColors[title]
          opacity: 0.5
          lineWidth: levelLineWidths[title]
          lineStyle: LineStyle[levelLineStyles[title]]
          axisLabelVisible: @data.levelLabelsVisible
          title: title

  addCandle: (data) ->
    candle = dataRowToCandle data
    @lastCandle = candle
    @candlesSeries.update candle

  setBarSpacing: (spacing) ->
    @chart.timeScale().applyOptions(barSpacing: spacing)
    @chart.timeScale().scrollToRealTime()

  gotoLastCandle: () ->
    @chart.timeScale().scrollToRealTime()
    # @chart.timeScale().fitContent()
    @setLegendFromCandle @lastCandle



dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

padNumber = (number, length = 2, filler = '0') -> number.toString().padStart(length, filler)

formatPrice = (price) ->
  return '' if price == undefined
  return price.toFixed(4) if price < 0.1
  if isOneChartPerPage
    if price < 10_000 then price.toFixed(2) else price
  else
    if price < 10_000 then String(price.toFixed(2)).padStart(9, '.') else price

formatTime = (ms) ->
  time = new Date(ms * 1000)
  hours = time.getHours()
  minutes = time.getMinutes()
  "#{padNumber hours}:#{padNumber minutes}"

formatDate = (ms) ->
  time = new Date(ms * 1000)
  "#{padNumber time.getUTCDate()}.#{padNumber time.getUTCMonth() + 1}.#{padNumber time.getUTCFullYear(), 4}"
