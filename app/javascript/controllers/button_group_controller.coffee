import { Controller } from "@hotwired/stimulus"

export default class extends Controller
  @values = { current: String }
  
  select: (e) ->
    e.preventDefault()
    e.target.blur()
    @currentValue = e.target.dataset.value
    document.dispatchEvent(new Event 'chart-must-update')

  currentValueChanged: ->
    for btn in @element.querySelectorAll('.btn') 
      btn.classList.remove('active')
      btn.classList.add('active') if btn.dataset.value == @currentValue
  