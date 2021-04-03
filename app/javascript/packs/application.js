// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

document.addEventListener("turbolinks:load", () => {
  document.querySelector('#list-config').addEventListener("change", e => {
    e.target.closest('form').submit()
  })

  document.querySelector('.tickers-table').addEventListener("change", e => {
    if (e.target.matches('.lots-input')) {
      let input = e.target
      let row = input.closest('tr')
      fetch(`/portfolio/${row.dataset.ticker}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lots: input.value })
      }).then(response => {
        console.log(response)
      })
    }
  })

  document.querySelector('.tickers-table').addEventListener("click", e => {
    if (e.target.matches('[data-sort]')) {
      let th = e.target
      console.log(th.dataset.sort)
      let sortKey = th.dataset.sort == 'ticker' ? '' : `aggregates.${th.dataset.sort}`
      document.querySelector('#order').value = sortKey
      document.querySelector('#list-config').submit()
    }
  })
})
