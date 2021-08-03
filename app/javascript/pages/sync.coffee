document.addEventListener "turbolinks:load", ->
  if document.querySelector('.arbitrages-page')
    refreshArbs = ->
      html = await $fetchText "/arbitrages"
      $q('.arbitrages-table').innerHTML = html

    $bind '.buttons .x-refresh', 'click', ->
      refreshArbs()

    loadOrders = ->
      html = await $fetchText "/orders"
      $q('.orders-table').innerHTML = html

    loadOrders()

    # setInterval(
    #   -> refreshArbs()
    #   5000
    # )
