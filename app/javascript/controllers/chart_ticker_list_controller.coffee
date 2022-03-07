import { Controller } from "@hotwired/stimulus"
import ChartsPage from '../pages/charts_page'

export default class extends Controller
  @prop 'chartedTickersField', -> $qs(".trading-page .charted-tickers-field")
  
  select: (e) ->
    e.preventDefault()
    item = e.target.closest('.ticker-item')
    @selectListTicker item.dataset.ticker if item
    
  keydown: (e) ->
    if e.key in ['ArrowDown', 'ArrowUp']
      e.preventDefault()
      currentItem = @element.querySelector('.ticker-item.active')
      nextItem = if e.key == 'ArrowDown' then currentItem?.nextSibling else currentItem?.previousSibling
      if nextItem && nextItem.dataset.ticker
        @selectListTicker nextItem.dataset.ticker

  selectListTicker: (ticker) ->
    tickers = @chartedTickersField.value.split(/\s/)
    tickers = _.without tickers, ticker
    tickers = [ ticker, ...tickers ].join(' ')
    @chartedTickersField.value = tickers
    document.dispatchEvent(new Event 'chart-must-update')

  markChartTickerActive: ->
    if ChartsPage.listIsOn
      currentTicker = $qs('.intraday-chart').dataset.ticker
      if currentTickerItem = @element.querySelector(".ticker-item[data-ticker=#{currentTicker}]")
        currentTickerItem.classList.add('active')