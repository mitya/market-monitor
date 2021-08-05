window.$fetch = (url, options) ->
  options ?= {}
  options.headers ?= {}
  options.headers['X-Requested-With'] = 'XMLHttpRequest'
  response = await fetch url, options

window.$fetchText = (url, options) ->
  response = await $fetch(url, options)
  await response.text()

window.$fetchJSON = (url, options) ->
  response = await $fetch(url, options)
  await response.json()

window.$qs = (selector) -> document.querySelector(selector)
window.$bind = (selector, event, handler) -> document.querySelector(selector).addEventListener event, handler
