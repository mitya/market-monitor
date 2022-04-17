import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'
import { Modal } from 'bootstrap'
import _ from 'lodash'


currentBarSpacing = 2
chartHeight = 0
isOneChartPerPage = false
isZeroScale = isOneChartPerPage


export default class Chart
  @prop 'legend', -> @container.querySelector('.intraday-chart-legend')


  # { ticker, candles, opens, levels, timeScaleVisible, priceScaleVisible, wheelScaling, levelLabelsVisible, levelsVisible, rows }
  constructor: (data) ->
    @data = data
    @ticker = data.ticker

    # timestamps = data.candles.map((c) -> c[0])
    # console.log timestamps.length
    # console.log _.uniq(timestamps).length
    # data.candles = data.candles[0..200]

    @root = document.querySelector('.intraday-charts')

    singleMode = $qs('.chart-tickers-list') != null
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
          </div>
        </div>
      </div>
    ")

    @container = @root.lastChild

    currentBarSpacing = parseInt(@root.dataset.barSpacing)
    currentRowsPerPage = parseInt(@root.dataset.rows)
    currentColsPerPage = parseInt(@root.dataset.cols)
    navbarHeight = 0 # document.querySelector('.main-navbar').offsetHeight
    toolbarHeight = document.querySelector('.trading-toolbar').offsetHeight + 8
    chartContainerHeight = window.innerHeight - navbarHeight - toolbarHeight
    chartHeight = (chartContainerHeight - 4 * 2 * currentRowsPerPage) / currentRowsPerPage

    isOneChartPerPage = currentRowsPerPage == 1 && currentColsPerPage == 1

    @chart = createChart @container.querySelector('.intraday-chart-content'), {
      width: 0
      height: chartHeight
      timeScale:
        timeVisible: true
        secondsVisible: false
        visible: @data.timeScaleVisible
        barSpacing: currentBarSpacing
        rightOffset: if singleMode then 5 else 0
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
    }
    @chart.subscribeCrosshairMove @onCrosshairMove

    candlesData = @data.candles.map dataRowToCandle
    @lastCandle = candlesData[candlesData.length - 1]
    @candlesSeries = @chart.addCandlestickSeries(
      # priceLineVisible: false,
      autoscaleInfoProvider: (original) ->
        res = original()
        res.priceRange.minValue = 0 if isZeroScale && res
        res
      # autoscaleInfoProvider: -> {
      #   priceRange: { minValue: 0, maxValue: 80 },
      #   margins: { above: 50, below: 50 },
      # }
    )
    @candlesSeries.setData candlesData

    volumeData  = @data.candles.map dataRowToVolume
    @volumeSeries = @chart.addHistogramSeries
      priceFormat:
        type: 'volume'
      priceLineVisible: false
      color: 'rgba(76, 76, 76, 0.3)'
      priceScaleId: ''
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
      @setLegendFromCandle { ...candle, time: param.time }
    else
      @setLegendFromCandle @lastCandle

  setLegendFromCandle: (candle) =>
    legend = @legend
    changeBox = legend.querySelector('.change-percent')
    if candle
      formattedPrice = candle.close.toFixed(2)
      formattedTime = formatTime(candle.time - 3 * 60 * 60)
      legend.querySelector('.candle-time').innerText = formattedTime
      legend.querySelector('.candle-price').innerText = formattedPrice

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
    levelColors =     { MA20: 'blue',   MA50: 'red',     MA100: 'magenta', MA200: 'red',     open: 'orange',  close: 'orange',   intraday: 'gray'  , swing: 'black' }
    levelLineStyles = { MA20: 'Dashed',  MA50: 'Dashed',   MA100: 'Solid',   MA200: 'Dashed',   open: 'Dotted', close: 'Solid',  intraday: 'Dotted', swing: 'Solid'}
    levelLineWidths = { MA20: 2,        MA50: 2,         MA100: 2,         MA200: 2,         open: 2,        close: 2,         intraday: 2       , swing: 1      }

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
    @setLegendFromCandle @lastCandle



dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

padNumber = (number, length = 2, filler = '0') -> number.toString().padStart(length, filler)

formatPrice = (price) ->
  if isOneChartPerPage
    if price < 10_000 then price.toFixed(2) else price
  else
    if price < 10_000 then String(price.toFixed(2)).padStart(9, '.') else price

formatTime = (ms) ->
  time = new Date(ms * 1000)
  hours = time.getHours()
  minutes = time.getMinutes()
  "#{padNumber hours}:#{padNumber minutes}"
