import { Controller } from "@hotwired/stimulus"
import { createChart, CrosshairMode, LineStyle, PriceScaleMode } from 'lightweight-charts'
import { Modal } from 'bootstrap'
import { UrlHelper } from '../pages/helpers'
import _ from 'lodash'
import Chart from '../pages/chart'
import ChartsPage from '../pages/charts_page'

export default class extends Controller
  connect: ->
    @charts = {}
    @currentBarSpacing = 2
    @chartHeight = 0

    @intervalSelector     = $qs(".trading-page [name=interval]")
    @columnsSelector      = $qs(".trading-page [name=columns]")
    @rowsSelector         = $qs(".trading-page [name=rows]")
    @chartedTickersField  = $qs(".trading-page [name=charted-tickers]")
    @timeScaleToggle      = $qs('.trading-page #toggle-time')
    @priceScaleToggle     = $qs('.trading-page #toggle-price')
    @wheelScalingToggle   = $qs('.trading-page #toggle-wheel-scaling')
    @levelLabelsToggle    = $qs('.trading-page #toggle-level-labels')
    @levelsToggle         = $qs('.trading-page #toggle-levels')

    $qs('#chart-settings-modal .x-save').addEventListener 'click', @updateOtherSettings

    @loadCharts()
    setInterval @refreshCharts, 15_000

  reload: ->
    location.reload()

  clearCharts: ->
    document.querySelector('.intraday-charts').innerHTML = ''

  loadCharts: ->
    @clearCharts()
    data = await $fetchJSON "/trading/candles#{if ChartsPage.listIsOn then "?single=1" else ''}"
    for ticker, payload of data
      @charts[ticker] = new Chart {
        timeScaleVisible:      @timeScaleToggle.checked,
        priceScaleVisible:    @priceScaleToggle.checked,
        levelLabelsVisible:  @levelLabelsToggle.checked,
        wheelScaling:       @wheelScalingToggle.checked,
        levelsVisible:            @levelsToggle.checked,
        ...payload,
      }
    document.dispatchEvent(new Event 'chart-loaded')

  refreshCharts: =>
    data = await $fetchJSON "/trading/candles?limit=1#{if ChartsPage.listIsOn then "&single=1" else ''}"
    for ticker, payload of data
      @charts[ticker].addCandle payload.candles[0]
      @charts[ticker].gotoLastCandle()

  updateChartSettings: (options = {}) ->
    chart_tickers    =  @chartedTickersField.value
    period           =     @intervalSelector.dataset.buttonGroupCurrentValue
    columns          =      @columnsSelector.dataset.buttonGroupCurrentValue
    rows             =         @rowsSelector.dataset.buttonGroupCurrentValue
    time_shown       =      @timeScaleToggle.checked
    price_shown      =     @priceScaleToggle.checked
    wheel_scaling    =   @wheelScalingToggle.checked
    level_labels     =    @levelLabelsToggle.checked
    levels_shown     =         @levelsToggle.checked
    bar_spacing      =    @currentBarSpacing

    await $fetchJSON "/trading/update_chart_settings", method: 'POST', data: {
      chart_tickers, period, columns, rows, time_shown, price_shown, bar_spacing, wheel_scaling, level_labels, levels_shown
    }
    @reload() unless options?.reload == false

  updateOtherSettings: =>
    console.log 'updateOtherSettings'

    tickerSetsText = $qs('.ticker-sets textarea').value
    await $fetchJSON "/trading/update_ticker_sets", method: 'POST', data: { text: tickerSetsText }

    intradayLevelsText = $qs("#chart-settings-modal .intraday-levels textarea").value
    await $fetchJSON "/trading/update_intraday_levels", method: 'POST', data: { text: intradayLevelsText }

    synced_tickers   = $qs("#chart-settings-modal .synced-tickers-field").value
    sync_ticker_sets = $qs('#chart-settings-modal #sync-ticker-sets-toggle').checked
    await $fetchJSON "/trading/update_chart_settings", method: 'POST', data: {
      synced_tickers, sync_ticker_sets
    }

    @reload()

  # selectTickerSet: (btn) ->
  #   chartedTickersField.value = btn.dataset.tickers
  #   other.classList.remove('active') for other in btn.closest('.list-group').querySelectorAll('.list-group-item')
  #   btn.classList.add('active')
  #   updateChartSettings()
  #   reload()


  zoom: (e) ->
    e.preventDefault()
    e.target.blur()
    e.target.blur()
    step = Number(e.target.dataset.value)
    @currentBarSpacing = @currentBarSpacing + step
    for ticker, chart of @charts
      chart.setBarSpacing @currentBarSpacing # current = chart.timeScale().options().barSpacing
    @updateChartSettings reload: false

  toggleTimeScale: (e) ->
    e.target.blur()
    for ticker, { chart } of @charts
      chart.applyOptions timeScale: { visible: e.target.checked }
    @updateChartSettings reload: false

  togglePriceScale: (e) ->
    e.target.blur()
    for ticker, { chart } of @charts
      chart.applyOptions priceScale: { visible: e.target.checked }
    @updateChartSettings reload: false

  toggleWheelScaling: (e) ->
    for ticker, { chart } of @charts
      chart.applyOptions handleScale: { mouseWheel: e.target.checked }
    @updateChartSettings reload: false

  toggleLevelLabels: (e) ->
    @updateChartSettings reload: true

  toggleLevels: (e) ->
    @updateChartSettings reload: true

  toggleFullScreen: ->
    UrlHelper.toggleParam "full-screen"

  toggleTickersList: ->
    if UrlHelper.hasParam('list')
      UrlHelper.toggleParam "list"
    else
      UrlHelper.setParams list: 1, 'full-screen': 1

  gotoEnd: ->
    for ticker, { chart } of @charts
      chart.timeScale().scrollToRealTime()

  gotoDown: ->
    window.scrollBy 0, @chartHeight * 2

  gotoUp: ->
    window.scrollBy 0, -(@chartHeight * 2)

  openSettings: ->
    modal = new Modal document.getElementById 'chart-settings-modal'
    modal.show()

  changeTickerSet: (e) ->
    @chartedTickersField.value = e.target.value
    @updateChartSettings()
