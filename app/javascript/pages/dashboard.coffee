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

    $delegate '.arbitrages-table', '.limit-order-button', 'click', (button, e) ->
      { ticker, operation, price, lots } = button.dataset
      result = await $fetchJSON "/arbitrages/limit_order", method: 'POST', data: { ticker, operation, price, lots }
      console.log result

  if $qs('.activities-page')
    loadOrders()
    loadOperations()
    loadPortfolio()
