document.addEventListener "turbolinks:load", ->
  if document.querySelector('.arbitrages-page')
    refreshArbs = ->
      html = await $fetchText "/arbitrages"
      $q('.arbitrages-table').innerHTML = html
      
    $bind '.buttons .x-refresh', 'click', ->
      refreshArbs()


    # setInterval(
    #   -> refreshArbs()
    #   5000
    # )
