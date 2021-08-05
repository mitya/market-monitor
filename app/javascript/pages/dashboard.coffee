document.addEventListener "turbolinks:load", ->
  loadArbs = ->
    $qs('.arbitrages-table').innerHTML = await $fetchText "/arbitrages"
  loadOrders = ->
    data = await $fetchJSON "/orders"
    $qs('.orders-table.buys').innerHTML = data.buys
    $qs('.orders-table.sells').innerHTML = data.sells
  loadOperations = ->
    $qs('.operations-table').innerHTML = await $fetchText "/operations"
  loadPortfolio = ->
    $qs('.portfolio-table').innerHTML = await $fetchText "/portfolio"


  if $qs('.arbitrages-page')
    $bind '.buttons .x-refresh', 'click', -> loadArbs()

  if $qs('.activities-page')
    loadOrders()
    loadOperations()
    loadPortfolio()
