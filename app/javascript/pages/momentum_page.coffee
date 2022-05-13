import { UrlHelper } from './helpers'

document.addEventListener "turbolinks:load", ->
  return unless $qs('.momentum-table')

  # setInterval (-> location.reload()), 20_000

  document.addEventListener 'click', (e) ->
    if link = e.target.closest('.x-copy-tickers')
      e.stopImmediatePropagation()
      syncChannel.setChartTicker(link.dataset.tickers)

  $delegate '.momentum-table', 'th[data-sort]', 'click', (th, e) ->
    table = th.closest('table')
    sortParam = table.dataset.sortParam || 'sort'
    UrlHelper.replaceLocationParams "#{sortParam}": th.dataset.sort

  $delegate '.momentum-table', '.ticker-item', 'click', (element, e) ->
    syncChannel.setChartTicker(element.innerText)
