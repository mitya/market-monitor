window.$fetchText = (url, options) ->
  options ?= {}
  options.headers ?= {}
  options.headers['X-Requested-With'] = 'XMLHttpRequest'
  response = await fetch url, options
  text = await response.text()

window.$q = (selector) -> document.querySelector(selector)
window.$bind = (selector, event, handler) -> document.querySelector(selector).addEventListener event, handler
