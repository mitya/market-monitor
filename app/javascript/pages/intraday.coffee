import { createChart, CrosshairMode, LineStyle } from 'lightweight-charts'

charts = {}

window.getCharts = -> charts

chartsContainer = -> document.querySelector('.intraday-charts')
clearCharts = -> 
  chartsContainer().innerHTML = ''
  charts = {}
  
dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

makeChart = (ticker, data) ->
  chartsContainer().insertAdjacentHTML('beforeend', "
    <div class='intraday-chart'>
      <div class='intraday-chart-legend'>
        <span class='chart-ticker'></span>
        <span class='candle-change'></span>
      </div>
    </div>
  ")
  container = chartsContainer().lastChild
  legend = container.querySelector('.intraday-chart-legend')
  
  candles = data[ticker]
  candlesData = candles.map dataRowToCandle
  volumeData = candles.map dataRowToVolume

  priceFormatter = (price) -> if price < 100 then String(price.toFixed(2)).padStart(7, ' ') else price
  
  chart = createChart container, { 
    width: 0, height: 280, 
    timeScale: { timeVisible: true, secondsVisible: false },
    priceScale: { entireTextOnly: true },
    localization: {
      priceFormatter: priceFormatter
    },
  }
  
  lineSeries = chart.addCandlestickSeries()  
  lineSeries.setData candlesData

  volumeSeries = chart.addHistogramSeries({
    priceFormat: { type: 'volume' }, 
    priceLineVisible: false, 
    color: 'rgba(76, 76, 76, 0.5)', 
    priceScaleId: 'x', scaleMargins: { top: 0.85, bottom: 0 },
  })  
  volumeSeries.setData volumeData
  
  legend.querySelector('.chart-ticker').innerText = ticker
  
  chart.subscribeCrosshairMove (param) -> 
    if (param.time)
      candle = Array.from( param.seriesPrices.values() )[0]
      legend.querySelector('.candle-change').innerText = candle.close.toFixed(2)
    else
      legend.querySelector('.candle-change').innerText = ''
  
  
  charts[ticker] = { chart: chart, candles: lineSeries, volume: volumeSeries }
  
  # # circle arrowDown arrowUp
  # lineSeries.setMarkers [
  #   { time: candlesData[candlesData.length - 10].time, position: 'aboveBar', color: 'red', shape: 'arrowDown', text: '2Top' },
  #   { time: candlesData[candlesData.length - 20].time, position: 'belowBar', color: 'green', shape: 'arrowUp', text: 'Level' },
  # ]

document.addEventListener "turbolinks:load", ->
  if document.querySelector('.intraday-charts')
    period = 3
    tickers = 'CLF VEON MOMO ZIM'    
    tickers = tickers.replaceAll(' ', '+')    

    intervalSelector = $qs(".trading-page .interval-selector")
    chartedTickersField = $qs(".trading-page .charted-tickers-field")
    syncedTickersField = $qs(".trading-page .synced-tickers-field")

    loadCharts = ->
      data = await $fetchJSON "/trading/candles?tickers=#{tickers}&period=#{period}"    
      clearCharts()
      for ticker, candles of data
        makeChart ticker, data
      
    refreshCharts = ->
      data = await $fetchJSON "/trading/candles?limit=1&tickers=#{tickers}&period=#{period}"
      for ticker, rows of data
        candle = dataRowToCandle rows[0]
        charts[ticker].candles.update candle
    
    updateChartSettings = ->
      charted_tickers = chartedTickersField.value
      synced_tickers = syncedTickersField.value
      period = intervalSelector.querySelector('.btn.active').dataset.interval
      await $fetchJSON "/trading/update_chart_settings", method: 'POST', data: { charted_tickers, synced_tickers, period }
        
    bindToolbar = ->
      
      $bind intervalSelector, 'click', (e) ->
        button = $qs(e.target)
        other.classList.remove('active') for other in button.closest('.btn-group').querySelectorAll('.btn')
        button.classList.add('active')
        button.blur()
        updateChartSettings()
      intervalSelector.querySelector(".btn[data-interval='#{intervalSelector.dataset.initial}']").classList.add('active')

      $bind chartedTickersField, 'change', (e) -> updateChartSettings()
      $bind syncedTickersField, 'change', (e) -> updateChartSettings()
    
    
    bindToolbar()
    loadCharts()
    setInterval refreshCharts, 10_000
