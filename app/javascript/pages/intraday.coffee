import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'

charts = {}

window.getCharts = -> charts

chartsContainer = -> document.querySelector('.intraday-charts')
clearCharts = -> 
  chartsContainer().innerHTML = ''
  charts = {}
  
dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

makeChart = ({ ticker, candles, opens, levels, timeScaleVisible, priceScaleVisible }) ->
  chartsContainer().insertAdjacentHTML('beforeend', "
    <div class='intraday-chart col ps-4 pe-4 pb-4 pt-2'>
      <div class='intraday-chart-content'>
        <div class='intraday-chart-legend'>
          <span class='chart-ticker'></span>
          <span class='candle-change'></span>
        </div>
      </div>
    </div>
  ")
  container = chartsContainer().lastChild
  legend = container.querySelector('.intraday-chart-legend')
  
  candlesData = candles.map dataRowToCandle
  volumeData = candles.map dataRowToVolume
  
  priceFormatter = (price) -> if price < 10_000 then String(price.toFixed(2)).padStart(9, '.') else price
  
  chart = createChart container.querySelector('.intraday-chart-content'), { 
    width: 0, height: 420, 
    timeScale: { timeVisible: true, secondsVisible: false, visible: timeScaleVisible, barSpacing: 10 },
    rightPriceScale: { 
      entireTextOnly: true, 
      visible: priceScaleVisible,
      mode: PriceScaleMode.Percentage,
    },   		
    localization: {
      priceFormatter: priceFormatter
    },
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
  
  setDefaultLegend = ->
    lastCandle = charts[ticker].lastCandle
    defaultText = if lastCandle then lastCandle.close.toFixed(2) else ''
    changeBox = legend.querySelector('.candle-change')
    changeBox.innerText = defaultText
  setDefaultLegend()
  
  chart.subscribeCrosshairMove (param) -> 
    if (param.time)
      candle = Array.from( param.seriesPrices.values() )[0]
      legend.querySelector('.candle-change').innerText = candle.close.toFixed(2)
    else
      setDefaultLegend()
  
  if opens
    candlesSeries.setMarkers opens.map (openingTime) -> 
      { time: openingTime, position: 'aboveBar', color: 'orange', shape: 'circle', text: 'O' }
    
  levelColors =     { MA20: 'cyan',   MA50: 'magenta', MA100: 'magenta', MA200: 'magenta', open: 'orange', close: 'black',  intraday: 'gray' }
  levelLineStyles = { MA20: 'Solid',  MA50: 'Solid',   MA100: 'Solid',   MA200: 'Solid',   open: 'Solid',  close: 'Solid',  intraday: 'Dotted' }
  levelLineWidths = { MA20: 2,        MA50: 2,         MA100: 2,         MA200: 2,         open: 2,        close: 2,        intraday: 2 }
  
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
        axisLabelVisible: false
        title: title

  # chart.timeScale().fitContent()
    
  # # circle arrowDown arrowUp
  # lineSeries.setMarkers [
  #   { time: candlesData[candlesData.length - 10].time, position: 'aboveBar', color: 'red', shape: 'arrowDown', text: '2Top' },
  #   { time: candlesData[candlesData.length - 20].time, position: 'belowBar', color: 'green', shape: 'arrowUp', text: 'Level' },
  # ]




document.addEventListener "turbolinks:load", ->
  if document.querySelector('.intraday-charts')
    intervalSelector    = $qs(".trading-page .interval-selector")
    columnsSelector     = $qs(".trading-page .columns-selector")
    chartedTickersField = $qs(".trading-page .charted-tickers-field")
    syncedTickersField  = $qs(".trading-page .synced-tickers-field")
    intradayLevelsField = $qs(".trading-page .intraday-levels textarea")
    timeScaleToggle     = $qs('.trading-page #toggle-time')
    priceScaleToggle    = $qs('.trading-page #toggle-price')
    gotoEndButton       = $qs('.trading-page .go-to-end')
    syncTickerSetsToggle= $qs('.trading-page #sync-ticker-sets-toggle')

    reload = ->
      location.reload()

    loadCharts = ->
      data = await $fetchJSON "/trading/candles"    
      console.log data
      clearCharts()
      for ticker, payload of data
        makeChart { ...payload, timeScaleVisible: timeScaleToggle.checked, priceScaleVisible: priceScaleToggle.checked }
      
    refreshCharts = ->
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
      time_shown = timeScaleToggle.checked
      price_shown = priceScaleToggle.checked
      sync_ticker_sets = syncTickerSetsToggle.checked
      await $fetchJSON "/trading/update_chart_settings", method: 'POST', data: { 
        chart_tickers, synced_tickers, period, columns, time_shown, price_shown, sync_ticker_sets 
      }
      reload() unless options?.reload == false

    updateIntradayLevels = ->
      text = intradayLevelsField.value
      await $fetchJSON "/trading/update_intraday_levels", method: 'POST', data: { text }
      reload()
      
    updateTickerSets = ->
      text = $qs('.ticker-sets textarea').value
      await $fetchJSON "/trading/update_ticker_sets", method: 'POST', data: { text }
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

      $bind timeScaleToggle, 'change', ->
        for ticker, { chart } of charts
          chart.applyOptions timeScale: { visible: timeScaleToggle.checked } 
        updateChartSettings reload: false

      $bind priceScaleToggle, 'change', ->
        for ticker, { chart } of charts
          chart.applyOptions priceScale: { visible: priceScaleToggle.checked } 
        updateChartSettings reload: false      
      
      $bind gotoEndButton, 'click', ->
        chart.timeScale().scrollToRealTime() for ticker, { chart } of charts
      
      $bind chartedTickersField, 'change', updateChartSettings
      $bind syncedTickersField, 'change', updateChartSettings
      $bind syncTickerSetsToggle, 'change', -> updateChartSettings reload: false
      $bind $qs('.intraday-levels .btn'), 'click', updateIntradayLevels
      $bind $qs('.ticker-sets .btn'), 'click', updateTickerSets

      $bind $qs('.ticker-set-selector'), 'change', (e) ->
        tickersLine = e.target.value
        chartedTickersField.value = tickersLine
        updateChartSettings()
      
    
      $delegate '.trading-page', '.zoom-chart', 'click', (target) ->
        target.blur()
        step = Number(target.dataset.value)
        for ticker, { chart } of charts
          current = chart.timeScale().options().barSpacing
          chart.timeScale().applyOptions(barSpacing: current + step)
          chart.timeScale().scrollToRealTime()
    
    
    bindToolbar()
    loadCharts()
    setInterval refreshCharts, 10_000
