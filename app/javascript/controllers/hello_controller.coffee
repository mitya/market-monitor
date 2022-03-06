import { Controller } from "@hotwired/stimulus"

export default class extends Controller
  connect: ->
    @element.textContent = "Hello World!!!!"
