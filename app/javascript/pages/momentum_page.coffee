import { UrlHelper } from './helpers'

document.addEventListener "turbolinks:load", ->
  return unless $qs('.momentum-table')

  # setInterval (-> location.reload()), 20_000

  selectRow = (row) ->
    other.classList.remove('selected-row') for other in document.querySelectorAll('.selected-row')
    row.classList.add('selected-row')

  setChartTicker = (ticker) ->
    syncChannel.setChartTicker(ticker) if ticker

  document.addEventListener 'click', (e) ->
    if link = e.target.closest('.x-copy-tickers')
      e.stopImmediatePropagation()
      setChartTicker link.dataset.tickers

    if target = e.target.closest('.ticker-item')
      return if e.detail == 2
      setChartTicker target.innerText

    if link = e.target.closest('.x-remove-row')
      e.preventDefault()
      row = link.closest('tr')
      response = await $fetchJSON link.href, method: 'DELETE'
      row.remove()

    if row = e.target.closest('tr[data-fn~=row-selector]')
      selectRow row

  document.addEventListener 'dblclick', (e) ->
    if target = e.target.closest('.ticker-item')
      syncChannel.cancelChartUpdate()
      result = await $fetchJSON "/ticker_sets/favorites/items/#{target.dataset.ticker}/toggle", method: 'POST'
      for item in document.querySelectorAll(".ticker-item[data-ticker='#{result.ticker}']")
        item.classList[if result.included then 'add' else 'remove']('watched')

  document.addEventListener 'keydown', (e) ->
    return unless e.key in ['ArrowDown', 'ArrowUp']
    if selectedRow = document.querySelector("tr.selected-row")
      e.preventDefault()
      if nextRow = (if e.key == 'ArrowDown' then selectedRow.nextSibling else selectedRow.previousSibling)
        selectRow nextRow
        setChartTicker nextRow.querySelector('.ticker-item')?.dataset?.ticker

  document.querySelectorAll('.watch-adder').forEach (form) ->
    form.addEventListener 'submit', (e) ->
      e.preventDefault()
      response = await $fetchJSON "/watched_targets", method: 'POST', data: { text: form.querySelector('input').value }
      if response.ok
        form.reset()
        targetTable = document.querySelector(".watches-table[data-key='#{response.list}'] tbody")
        targetTable.insertAdjacentHTML 'beforeend', response.html

  document.querySelectorAll('.ticker-set-adder').forEach (form) ->
      form.addEventListener 'submit', (e) ->
        e.preventDefault()
        response = await $fetchJSON "/ticker_sets/#{form.dataset.setId}/items", method: 'POST', data: { text: form.querySelector('input').value }
        if response.ok
          form.reset()

  $delegate '.momentum-table', 'th[data-sort]', 'click', (th, e) ->
    table = th.closest('table')
    sortParam = table.dataset.sortParam || 'sort'
    UrlHelper.replaceLocationParams "#{sortParam}": th.dataset.sort
