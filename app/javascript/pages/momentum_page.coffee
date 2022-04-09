import { UrlHelper } from './helpers'

document.addEventListener "turbolinks:load", ->
  return unless $qs('.momentum-table')
  $delegate '.momentum-table', 'th[data-sort]', 'click', (th, e) ->
    UrlHelper.replaceLocationParams sort: th.dataset.sort
