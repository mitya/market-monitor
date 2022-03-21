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

window.$qs = (selector) -> 
  if selector instanceof Node
    selector
  else
    document.querySelector(selector)

window.$bind = (selector, event, handler) -> $qs(selector).addEventListener event, handler
window.$delegate = (container, selector, event, handler) ->
  selector = "#{container} #{selector}"
  document.addEventListener event, (e) ->
    closest = e.target.closest(selector)
    if e.target.matches(selector) || closest
      handler.bind(closest || e.target, closest || e.target, e)()

Function::prop = (name, getter, setter) -> Object.defineProperty this::, name, get: getter, set: setter
Function::cprop = (name, getter) -> Object.defineProperty this, name, get: getter

export UrlHelper = 
  hasParam: (name) ->
    new URL(location.href).searchParams.get(name) != null

  toggleParam: (name) ->
    url = new URL(location.href)
    if url.searchParams.get(name) == '1'
      url.searchParams.delete name
    else
      url.searchParams.set name, '1'
    location.assign url
    
  setParams: (pairs) ->
    url = new URL(location.href)
    for k, v of pairs
      url.searchParams.set k, v
    location.assign url
