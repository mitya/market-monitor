import { UrlHelper } from './helpers'

document.addEventListener "turbolinks:load", ->
  return unless $qs('.momentum-table')

  # setInterval (-> location.reload()), 20_000

  $delegate '.momentum-table', 'th[data-sort]', 'click', (th, e) ->
    UrlHelper.replaceLocationParams sort: th.dataset.sort

  $delegate '.momentum-table', '.ticker-item', 'click', (element, e) ->
    syncChannel.setChartTicker(element.innerText)
