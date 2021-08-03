document.addEventListener "turbolinks:load", ->
  if document.querySelector('.arbitrages-page')
    loadArbs = ->
      $q('.arbitrages-table').innerHTML = await $fetchText "/arbitrages"
    loadOrders = ->
      $q('.orders-table').innerHTML = await $fetchText "/orders"
    loadOperations = ->
      $q('.operations-table').innerHTML = await $fetchText "/operations"

    $bind '.buttons .x-refresh', 'click', -> loadArbs()

    loadOrders()
    loadOperations()
