import { UrlHelper } from './helpers'

document.addEventListener "turbolinks:load", ->
  return unless $qs('.momentum-table')

  # setInterval (-> location.reload()), 20_000

  document.addEventListener 'click', (e) ->
    if link = e.target.closest('.x-copy-tickers')
      e.stopImmediatePropagation()
      syncChannel.setChartTicker(link.dataset.tickers)
    if target = e.target.closest('.ticker-item')
      return if e.detail == 2
      syncChannel.setChartTicker(target.innerText)

  document.addEventListener 'dblclick', (e) ->
    if target = e.target.closest('.ticker-item')
      syncChannel.cancelChartUpdate()
      result = await $fetchJSON "/ticker_sets/favorites/items/#{target.dataset.ticker}/toggle", method: 'POST'
      for item in document.querySelectorAll(".ticker-item[data-ticker='#{result.ticker}']")
        item.classList[if result.included then 'add' else 'remove']('watched')

  $delegate '.momentum-table', 'th[data-sort]', 'click', (th, e) ->
    table = th.closest('table')
    sortParam = table.dataset.sortParam || 'sort'
    UrlHelper.replaceLocationParams "#{sortParam}": th.dataset.sort
