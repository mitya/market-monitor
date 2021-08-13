window.$fetch = (url, { data, ...options } = { }) ->
  options ?= {}
  options.headers ?= {}
  options.headers['X-Requested-With'] = 'XMLHttpRequest'
  if data
    options.body = JSON.stringify(data)
    options.headers['Content-Type'] = 'application/json'

  response = await fetch url, options

window.$fetchText = (url, options) ->
  response = await $fetch(url, options)
  await response.text()

window.$fetchJSON = (url, options) ->
  response = await $fetch(url, options)
  await response.json()

window.$qs = (selector) -> document.querySelector(selector)
window.$bind = (selector, event, handler) -> document.querySelector(selector).addEventListener event, handler
window.$delegate = (container, selector, event, handler) ->
  selector = "#{container} #{selector}"
  document.addEventListener event, (e) ->
    closest = e.target.closest(selector)
    if e.target.matches(selector) || closest
      handler.bind(closest || e.target, closest || e.target, e)()
