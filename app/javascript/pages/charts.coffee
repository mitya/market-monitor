import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'
import { Modal } from 'bootstrap'
import _ from 'lodash'
import Chart from './chart'
import ChartsPage from './charts_page'

charts = {}
currentBarSpacing = 2
chartHeight = 0

window.getCharts = -> charts

clearCharts = ->
  document.querySelector('.intraday-charts').innerHTML = ''
  charts = {}

urlHasParam = (name) ->
  new URL(location.href).searchParams.get(name) != null

toggleUrlParam = (name) ->
  url = new URL(location.href)
  if url.searchParams.get(name) == '1'
    url.searchParams.delete name
  else
    url.searchParams.set name, '1'
  location.assign url
  
setUrlParams = (pairs) ->
  url = new URL(location.href)
  for k, v of pairs
    url.searchParams.set k, v
  location.assign url


document.addEventListener "turbolinks:load", ->
  if document.querySelector('.intraday-charts')
    intervalSelector    = $qs(".trading-page [name=interval]")
    columnsSelector     = $qs(".trading-page [name=columns]")
    rowsSelector        = $qs(".trading-page [name=rows]")
    
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
      clearCharts()
      data = await $fetchJSON "/trading/candles#{if ChartsPage.listIsOn then "?single=1" else ''}"
      for ticker, payload of data
        charts[ticker] = new Chart {
          timeScaleVisible:   timeScaleToggle.checked, 
          priceScaleVisible:  priceScaleToggle.checked,
          levelLabelsVisible: levelLabelsToggle.checked,
          wheelScaling:       wheelScalingToggle.checked,
          levelsVisible:      levelsToggle.checked,
          ...payload,
        }
      document.dispatchEvent(new Event 'chart-loaded')

    refreshCharts = ->
      data = await $fetchJSON "/trading/candles?limit=1#{if ChartsPage.listIsOn then "&single=1" else ''}"
      for ticker, payload of data
        charts[ticker].addCandle payload.candles[0]
        charts[ticker].gotoLastCandle()

    updateChartSettings = (options = {}) ->
      chart_tickers = chartedTickersField.value
      synced_tickers = syncedTickersField.value
      period  = intervalSelector.dataset.buttonGroupCurrentValue
      columns = columnsSelector .dataset.buttonGroupCurrentValue
      rows    = rowsSelector    .dataset.buttonGroupCurrentValue
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
      document.addEventListener 'chart-must-update', (e) -> 
        updateChartSettings()
      
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
      
      $bind $qs('.toggle-tickers-list'), 'click', -> 
        if urlHasParam('list')
          toggleUrlParam "list"
        else
          setUrlParams list: 1, 'full-screen': 1
      
      $bind $qs('.ticker-set-selector'), 'change', (e) ->
        chartedTickersField.value = e.target.value
        updateChartSettings()
      
      $delegate '.trading-page', '.zoom-chart', 'click', (target) ->
        target.blur()
        step = Number(target.dataset.value)
        currentBarSpacing = currentBarSpacing + step
        for ticker, chart of charts
          chart.setBarSpacing currentBarSpacing # current = chart.timeScale().options().barSpacing
        updateChartSettings reload: false

    bindToolbar()
    loadCharts()
    setInterval refreshCharts, 10_000
