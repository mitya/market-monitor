// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import { Modal } from 'bootstrap'
import ApexCharts from 'apexcharts'

Rails.start()
Turbolinks.start()
ActiveStorage.start()

document.addEventListener("turbolinks:load", () => {
  document.querySelector('#list-config').addEventListener("change", e => {
    e.target.closest('form').submit()
  })

  let tickersTable = document.querySelector('.tickers-table')

  tickersTable.addEventListener("change", e => {
    if (e.target.matches('.lots-input')) {
      let input = e.target
      let row = input.closest('tr')
      fetch(`/portfolio/${row.dataset.ticker}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lots: input.value, account: input.dataset.account })
      }).then(response => {
        console.log(response)
      })
    }
  })

  tickersTable.addEventListener("click", e => {
    if (e.target.matches('[data-sort]')) {
      let th = e.target
      let sortKey = th.dataset.sort == 'ticker' ? '' : th.dataset.sort
      document.querySelector('#order').value = sortKey
      document.querySelector('#list-config').submit()
    } else if (e.target.matches('.open-chart')) {
      e.stopPropagation()
      let link = e.target

      let modal = new Modal(document.getElementById('chart-modal'))
      modal.show()
      renderChart(link.dataset.ticker)
    }
  })

  let tickersInput = document.querySelector('#tickers')
  if (tickersInput?.value) tickersInput.focus()
})

let chart = null

function renderChart(ticker) {
  fetch(`/instruments/${ticker}/candles`, { headers: { 'Content-Type': 'application/json' } }).then(response => response.json()).then(response => {
    document.querySelector('#chart-modal .tv-link').href = response.trading_view_url

    if (chart) chart.destroy()
    chart = new ApexCharts(document.querySelector("#the-chart"), {
      series: [{
        data: response.candles.map( ({ date, ohlc }) => [ Date.parse(date), ohlc ] )
      }],
      chart: {
        type: 'candlestick',
        height: 400,
        toolbar: { autoSelected: 'pan' },
        animations: { enabled: false },
      },
      title: { text: response.name, align: 'left' },
      xaxis: {
        type: 'datetime',
        labels: {
          format: 'MMM dd',
        }
      },
      yaxis: { tooltip: { enabled: true } }
    })
    chart.render()
  })
}
