import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'
import { Modal } from 'bootstrap'

charts = {}
currentBarSpacing = 7
currentBarSpacing = 2
chartHeight = 0

window.getCharts = -> charts

chartsContainer = -> document.querySelector('.intraday-charts')
clearCharts = ->
  chartsContainer().innerHTML = ''
  charts = {}

dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

makeChart = ({ ticker, candles, opens, levels, timeScaleVisible, priceScaleVisible, wheelScaling, levelLabelsVisible, levelsVisible, rows }) ->
  chartsContainer().insertAdjacentHTML('beforeend', "
    <div class='intraday-chart col ps-4 pe-4 pb-4 pt-2'>
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
  container = chartsContainer().lastChild
  legend = container.querySelector('.intraday-chart-legend')
  currentBarSpacing = parseInt(chartsContainer().dataset.barSpacing)
  currentRowsPerPage = parseInt(chartsContainer().dataset.rows)

  candlesData = candles.map dataRowToCandle
  volumeData = candles.map dataRowToVolume

  priceFormatter = (price) -> if price < 10_000 then String(price.toFixed(2)).padStart(9, '.') else price

  windowHeight = window.innerHeight
  navbarHeight = document.querySelector('.main-navbar').offsetHeight
  toolbarHeight = document.querySelector('.trading-toolbar').offsetHeight
  chartContainerHeight = windowHeight - navbarHeight - toolbarHeight
  chartHeight = chartContainerHeight / currentRowsPerPage - 25 * currentRowsPerPage
  chartHeight = chartContainerHeight / currentRowsPerPage - 70 if currentRowsPerPage == 1
  chartHeight = chartContainerHeight / currentRowsPerPage - 15 * currentRowsPerPage if currentRowsPerPage == 3

  chart = createChart container.querySelector('.intraday-chart-content'), {
    width: 0, height: chartHeight,
    timeScale: { timeVisible: true, secondsVisible: false, visible: timeScaleVisible, barSpacing: currentBarSpacing },
    rightPriceScale: {
      entireTextOnly: true,
      visible: priceScaleVisible,
      mode: PriceScaleMode.Normal, # PriceScaleMode.Percentage
      borderVisible: false,
    },
    localization: { priceFormatter: priceFormatter },
    grid: { horzLines: { visible: priceScaleVisible } },
    handleScale: { axisPressedMouseMove: true, mouseWheel: wheelScaling }
    handleScroll: true,    
  }

  candlesSeries = chart.addCandlestickSeries()
  candlesSeries.setData candlesData

  volumeSeries = chart.addHistogramSeries
    priceFormat: { type: 'volume' }
    priceLineVisible: false
    color: 'rgba(76, 76, 76, 0.5)'
    priceScaleId: '', scaleMargins: { top: 0.85, bottom: 0 }
  volumeSeries.setData volumeData

  legend.querySelector('.chart-ticker').innerText = ticker

  charts[ticker] = { chart: chart, candles: candlesSeries, volume: volumeSeries, lastCandle: candlesData[candlesData.length - 1] }

  setLegendFromCandle = (candle) ->
    changeBox = legend.querySelector('.change-percent')
    if candle
      formattedPrice = candle.close.toFixed(2)
      formattedTime = formatTime(candle.time - 3 * 60 * 60)
      legend.querySelector('.candle-time').innerText = formattedTime
      legend.querySelector('.candle-price').innerText = formattedPrice
  
      if openPrice = levels.open
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
  
  setLegendFromCandle charts[ticker].lastCandle
  
  chart.subscribeCrosshairMove (param) ->
    if (param.time)
      candle = Array.from( param.seriesPrices.values() )[0]
      setLegendFromCandle { ...candle, time: param.time }
    else
      setLegendFromCandle charts[ticker].lastCandle
  
  if opens
    candlesSeries.setMarkers opens.map (openingTime) ->
      { time: openingTime, position: 'aboveBar', color: 'orange', shape: 'circle', text: 'O' }
  
  levelColors =     { MA20: 'blue',   MA50: 'red',     MA100: 'magenta', MA200: 'red',     open: 'orange',  close: 'orange',   intraday: 'gray'  , swing: 'black' }
  levelLineStyles = { MA20: 'Dashed',  MA50: 'Dashed',   MA100: 'Solid',   MA200: 'Dashed',   open: 'Dotted', close: 'Solid',  intraday: 'Dotted', swing: 'Solid'}
  levelLineWidths = { MA20: 2,        MA50: 2,         MA100: 2,         MA200: 2,         open: 2,        close: 2,         intraday: 2       , swing: 1      }
  
  if levelsVisible
    for title, values of levels
      continue if values == null
      values = [values] unless values instanceof Array
      for level in values
        candlesSeries.createPriceLine
          price: Number(level)
          color: levelColors[title]
          opacity: 0.5
          lineWidth: levelLineWidths[title]
          lineStyle: LineStyle[levelLineStyles[title]]
          axisLabelVisible: levelLabelsVisible
          title: title

  # chart.timeScale().fitContent()
  # # circle arrowDown arrowUp
  # lineSeries.setMarkers [
  #   { time: candlesData[candlesData.length - 10].time, position: 'aboveBar', color: 'red', shape: 'arrowDown', text: '2Top' },
  #   { time: candlesData[candlesData.length - 20].time, position: 'belowBar', color: 'green', shape: 'arrowUp', text: 'Level' },
  # ]


padNumber = (number, length = 2, filler = '0') ->
  number.toString().padStart(length, filler)

formatTime = (ms) ->
  time = new Date(ms * 1000)
  hours = time.getHours()
  minutes = time.getMinutes()
  "#{padNumber hours}:#{padNumber minutes}"

toggleUrlParam = (name) ->
  url = new URL(location.href)
  if url.searchParams.get(name) == '1'
    url.searchParams.delete name
  else
    url.searchParams.set name, '1'
  location.assign url


document.addEventListener "turbolinks:load", ->
  if document.querySelector('.intraday-charts')
    intervalSelector    = $qs(".trading-page .interval-selector")
    columnsSelector     = $qs(".trading-page .columns-selector")
    rowsSelector        = $qs(".trading-page .rows-selector")
    chartedTickersField = $qs(".trading-page .charted-tickers-field")
    
    chartSettingsModal  = $qs('#chart-settings-modal')
    syncedTickersField  = $qs("#chart-settings-modal .synced-tickers-field")
    syncTickerSetsToggle= $qs('#chart-settings-modal #sync-ticker-sets-toggle')
    intradayLevelsField = $qs("#chart-settings-modal .intraday-levels textarea")
    
    timeScaleToggle     = $qs('.trading-page #toggle-time')
    priceScaleToggle    = $qs('.trading-page #toggle-price')
    wheelScalingToggle  = $qs('.trading-page #toggle-wheel-scaling')
    levelLabelsToggle   = $qs('.trading-page #toggle-level-labels')
    levelsToggle        = $qs('.trading-page #toggle-levels')
    gotoEndButton       = $qs('.trading-page .go-to-end')
    gotoDownButton      = $qs('.trading-page .go-down')
    gotoUpButton        = $qs('.trading-page .go-up')
    openSettingsButton  = $qs('.trading-page .open-settings')    

    reload = ->
      location.reload()

    loadCharts = ->
      data = await $fetchJSON "/trading/candles"
      console.log data
      clearCharts()
      for ticker, payload of data
        makeChart {
          timeScaleVisible:   timeScaleToggle.checked, 
          priceScaleVisible:  priceScaleToggle.checked,
          levelLabelsVisible: levelLabelsToggle.checked,
          wheelScaling:       wheelScalingToggle.checked,
          levelsVisible:      levelsToggle.checked,
          ...payload,
        }

    refreshCharts = ->
      return
      data = await $fetchJSON "/trading/candles?limit=1"
      for ticker, payload of data
        newCandle = dataRowToCandle payload.candles[0]
        charts[ticker].lastCandle = newCandle
        charts[ticker].candles.update newCandle

    updateChartSettings = (options = {}) ->
      chart_tickers = chartedTickersField.value
      synced_tickers = syncedTickersField.value
      period = intervalSelector.querySelector('.btn.active').dataset.value
      columns = columnsSelector.querySelector('.btn.active').dataset.value
      rows = rowsSelector.querySelector('.btn.active').dataset.value
      time_shown = timeScaleToggle.checked
      price_shown = priceScaleToggle.checked
      wheel_scaling = wheelScalingToggle.checked
      sync_ticker_sets = syncTickerSetsToggle.checked
      level_labels = levelLabelsToggle.checked
      levels_shown = levelsToggle.checked
      bar_spacing = currentBarSpacing

      await $fetchJSON "/trading/update_chart_settings", method: 'POST', data: {
        chart_tickers, synced_tickers, period, columns, rows, time_shown, price_shown, sync_ticker_sets, bar_spacing, wheel_scaling, level_labels, levels_shown
      }
      reload() unless options?.reload == false

    updateOtherSettings = ->
      tickerSetsText = $qs('.ticker-sets textarea').value
      intradayLevelsText = intradayLevelsField.value
      await $fetchJSON "/trading/update_ticker_sets", method: 'POST', data: { text: tickerSetsText }
      await $fetchJSON "/trading/update_intraday_levels", method: 'POST', data: { text: intradayLevelsText }
      reload()

    selectTickerSet = (btn) ->
      chartedTickersField.value = btn.dataset.tickers
      other.classList.remove('active') for other in btn.closest('.list-group').querySelectorAll('.list-group-item')
      btn.classList.add('active')
      updateChartSettings()
      reload()

    bindToolbar = ->
      $delegate '.trading-page', '.js-btn-group .btn', 'click', (button) ->
        other.classList.remove('active') for other in button.closest('.btn-group').querySelectorAll('.btn')
        button.classList.add('active')
        button.blur()
        updateChartSettings()

      intervalSelector.querySelector(".btn[data-value='#{intervalSelector.dataset.initial}']").classList.add('active')
      columnsSelector.querySelector(".btn[data-value='#{columnsSelector.dataset.initial}']").classList.add('active')
      rowsSelector.querySelector(".btn[data-value='#{rowsSelector.dataset.initial}']").classList.add('active')

      $bind timeScaleToggle, 'change', ->
        for ticker, { chart } of charts
          chart.applyOptions timeScale: { visible: timeScaleToggle.checked }
        updateChartSettings reload: false

      $bind priceScaleToggle, 'change', ->
        for ticker, { chart } of charts
          chart.applyOptions priceScale: { visible: priceScaleToggle.checked }
        updateChartSettings reload: false

      $bind wheelScalingToggle, 'change', ->
        for ticker, { chart } of charts
          chart.applyOptions handleScale: { mouseWheel: wheelScalingToggle.checked }
        updateChartSettings reload: false   

      $bind levelLabelsToggle, 'change', ->
        updateChartSettings reload: true   

      $bind levelsToggle, 'change', ->
        updateChartSettings reload: true   

      $bind gotoEndButton, 'click', ->
        chart.timeScale().scrollToRealTime() for ticker, { chart } of charts
        
      $bind gotoDownButton, 'click', -> window.scrollBy 0, chartHeight * 2
      $bind gotoUpButton, 'click', -> window.scrollBy 0, -(chartHeight * 2)
      
      $bind openSettingsButton, 'click', -> 
        modal = new Modal document.getElementById 'chart-settings-modal'
        modal.show()        

      $bind chartedTickersField, 'change', updateChartSettings
      $bind syncedTickersField, 'change', updateChartSettings
      $bind syncTickerSetsToggle, 'change', -> updateChartSettings reload: false
      
      $bind $qs('#chart-settings-modal .x-save'), 'click', updateOtherSettings

      $bind $qs('.toggle-full-screen'), 'click', -> toggleUrlParam "full-screen"
      $bind $qs('.toggle-tickers-list'), 'click', -> toggleUrlParam "list"
      
      $bind $qs('.ticker-set-selector'), 'change', (e) ->
        tickersLine = e.target.value
        chartedTickersField.value = tickersLine
        updateChartSettings()

      $delegate '.trading-page', '.zoom-chart', 'click', (target) ->
        target.blur()
        step = Number(target.dataset.value)
        currentBarSpacing = currentBarSpacing + step
        for ticker, { chart } of charts
          # current = chart.timeScale().options().barSpacing
          chart.timeScale().applyOptions(barSpacing: currentBarSpacing)
          chart.timeScale().scrollToRealTime()
        updateChartSettings reload: false

    bindToolbar()
    loadCharts()
    setInterval refreshCharts, 10_000
