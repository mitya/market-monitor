import { createChart, CrosshairMode, LineStyle } from 'lightweight-charts'

chartsContainer = -> document.querySelector('.intraday-charts')
clearChartContainer = -> chartsContainer().innerHTML = ''

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
  candlesData = candles.map (row) -> { time: row[0], open: row[1], high: row[2], low: row[3], close: row[4] }
  volumeData = candles.map (row) -> { time: row[0], value: row[5] }    

  priceFormatter = (price) -> if price < 100 then String(price.toFixed(2)).padStart(7, ' ') else price
  
  chart = createChart container, { 
    width: 0, height: 280, 
    timeScale: { timeVisible: true, secondsVisible: false },
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
  
  # # circle arrowDown arrowUp
  # lineSeries.setMarkers [
  #   { time: candlesData[candlesData.length - 10].time, position: 'aboveBar', color: 'red', shape: 'arrowDown', text: '2Top' },
  #   { time: candlesData[candlesData.length - 20].time, position: 'belowBar', color: 'green', shape: 'arrowUp', text: 'Level' },
  # ]

document.addEventListener "turbolinks:load", ->
  if document.querySelector('.intraday-charts')
    data = await $fetchJSON "/trading/candles"
    console.log data
    
    clearChartContainer()
    for ticker, candles of data
      makeChart ticker, data
