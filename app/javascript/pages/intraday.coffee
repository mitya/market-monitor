import { createChart, CrosshairMode, LineStyle } from 'lightweight-charts'

charts = {}

window.getCharts = -> charts

chartsContainer = -> document.querySelector('.intraday-charts')
clearCharts = -> 
  chartsContainer().innerHTML = ''
  charts = {}
  
dataRowToCandle = (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
dataRowToVolume = (row) -> { time: row[0], value: row[5] }

makeChart = ({ ticker, candles, opens, levels }) ->
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
  
  candlesSeries = chart.addCandlestickSeries()  
  candlesSeries.setData candlesData

  volumeSeries = chart.addHistogramSeries
    priceFormat: { type: 'volume' }
    priceLineVisible: false
    color: 'rgba(76, 76, 76, 0.5)'
    priceScaleId: 'x', scaleMargins: { top: 0.85, bottom: 0 }
  volumeSeries.setData volumeData
  
  legend.querySelector('.chart-ticker').innerText = ticker
  
  chart.subscribeCrosshairMove (param) -> 
    if (param.time)
      candle = Array.from( param.seriesPrices.values() )[0]
      legend.querySelector('.candle-change').innerText = candle.close.toFixed(2)
    else
      legend.querySelector('.candle-change').innerText = ''
  
  
  charts[ticker] = { chart: chart, candles: candlesSeries, volume: volumeSeries }
  
  candlesSeries.setMarkers opens.map (openingTime) -> { time: openingTime, position: 'aboveBar', color: 'orange', shape: 'circle', text: 'Open' }
    
  levelColors = { MA20: 'blue', MA50: 'green', MA100: 'orange', MA200: '#cc0000', open: 'orange', close: 'gray' }
  levelLineStyles = (name) -> if name.includes('MA') then LineStyle.Dashed else LineStyle.Dotted
  levelLineWidths = (name) -> if name.includes('MA') then 3 else 2
  
  for title, level of levels
    candlesSeries.createPriceLine
      price: level
      color: levelColors[title]
      opacity: 0.5
      lineWidth: levelLineWidths(title)
      lineStyle: levelLineStyles(title)
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
    intervalSelector = $qs(".trading-page .interval-selector")
    chartedTickersField = $qs(".trading-page .charted-tickers-field")
    syncedTickersField = $qs(".trading-page .synced-tickers-field")

    loadCharts = ->
      data = await $fetchJSON "/trading/candles"    
      console.log data
      clearCharts()
      for ticker, payload of data
        makeChart payload
      
    refreshCharts = ->
      data = await $fetchJSON "/trading/candles?limit=1"
      for ticker, payload of data
        charts[ticker].candles.update dataRowToCandle payload.candles[0]
    
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
