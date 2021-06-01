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
  document.querySelector('#list-config')?.addEventListener("change", e => {
    e.target.closest('form').submit()
  })

  let tickersTable = document.querySelector('.tickers-table')
  if (tickersTable) {
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
      } else if (e.target.matches('.instrument-name')) {
        let row = e.target.closest('tr')
        for (let other of row.parentNode.querySelectorAll('tr')) {
          other.classList.remove('selected-row')
        }
        row.classList.add('selected-row')
      }
    })
  }

  let tickersInput = document.querySelector('#tickers')
  if (tickersInput?.value)
    tickersInput.focus()
})

let chart = null
let volumeChart = null

function renderChart(ticker) {
  fetch(`/instruments/${ticker}/candles`, { headers: { 'Content-Type': 'application/json' } }).then(response => response.json()).then(response => {
    document.querySelector('#chart-modal .tv-link').href = response.trading_view_url
    document.querySelector('#chart-modal .modal-title').innerText = response.name

    const Y_LABELS_WIDTH = 80

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
        id: 'candles',
        group: 'main',
      },
      title: {
        text: `${response.ticker} — ${response.formatted_last_price}`,
        align: 'left'
      },
      xaxis: {
        type: 'datetime',
        labels: {
          format: 'MMM dd',
        }
        // type: 'category',
        // labels: {
        //   formatter: function(ms) {
        //     let date = new Date(ms)
        //     return `${date.getMonth()}/${date.getDate()} this year`
        //   }
        // }
      },
      yaxis: {
        tooltip: { enabled: true },
        labels: { minWidth: Y_LABELS_WIDTH, maxWidth: Y_LABELS_WIDTH }
      },
      // annotations: {
      //   xaxis: [
      //     {
      //       x: 'Oct 06 14:00',
      //       borderColor: '#00E396',
      //       label: {
      //         borderColor: '#00E396',
      //         style: {
      //           fontSize: '12px',
      //           color: '#fff',
      //           background: '#00E396'
      //         },
      //         orientation: 'horizontal',
      //         offsetY: 7,
      //         text: 'Annotation Test'
      //       }
      //     }
      //   ]
      // },
    })
    chart.render()

    if (volumeChart) volumeChart.destroy()
    volumeChart = new ApexCharts(document.querySelector("#volume-chart"), {
      series: [{
        name: 'volume',
        data: response.candles.map( ({ date, volume }) => [ Date.parse(date), volume ] )
      }],
      chart: {
        height: 160,
        type: 'bar',
        toolbar: { autoSelected: 'pan' },
        animations: { enabled: false },
        // group: 'main',
        // id: 'volume',
        // brush: {
        //   enabled: true,
        //   target: 'candles'
        // },
        // selection: {
        //   enabled: true,
        //   xaxis: {
        //     min: new Date('20 Jan 2017').getTime(),
        //     max: new Date('10 Dec 2017').getTime()
        //   },
        //   fill: {
        //     color: '#ccc',
        //     opacity: 0.4
        //   },
        //   stroke: {
        //     color: '#0D47A1',
        //   }
        // },
      },
      dataLabels: {
        enabled: false
      },

      // plotOptions: {
      //   bar: {
      //     columnWidth: '80%',
      //     colors: {
      //       ranges: [{
      //         from: -1000,
      //         to: 0,
      //         color: '#F15B46'
      //       }, {
      //         from: 1,
      //         to: 10000,
      //         color: '#FEB019'
      //       }],
      //
      //     },
      //   }
      // },
      xaxis: {
        type: 'datetime',
        labels: {
          format: 'MMM dd',
        }
        // axisBorder: { offsetX: 20 }
      },
      yaxis: {
        labels: {
          formatter: vol => vol.toLocaleString(),
          minWidth: Y_LABELS_WIDTH, maxWidth: Y_LABELS_WIDTH,
          // tooltip: { enabled: false },
        }
      }
    })

    volumeChart.render()
  })
}
