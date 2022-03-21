// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import { Modal } from 'bootstrap'
import ApexCharts from 'apexcharts'
import 'pages/helpers'
import 'pages/init'
import 'pages/charts_old'
import 'pages/dashboard'
import "channels"
import "controllers"

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
      if (e.target.matches('.portfolio-item-checker')) {
        let checkbox = e.target
        let row = checkbox.closest('tr')
        console.log(row.dataset.ticker, checkbox.checked)
        fetch(`/portfolio/${row.dataset.ticker}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ active: checkbox.checked })
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
      } else if (e.target.matches('.open-chart') || e.target.closest('.open-chart')) {
        e.stopPropagation()
        let link = e.target
        let row = e.target.closest('tr')

        let modal = new Modal(document.getElementById('chart-modal'))
        modal.show()
        renderChart(link.dataset.ticker || row.dataset.ticker)
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

  let tickerInput = document.querySelector('#ticker')
  if (tickerInput?.value)
    tickerInput.focus()

  let chartModal = document.querySelector('#chart-modal')
  if (chartModal) {
    chartModal.addEventListener("click", e => {
      if (e.target.matches('.x-change-chart')) {
        let down = e.target.matches('.x-next-chart')
        let button = e.target
        let modal = button.closest('#chart-modal')
        let ticker = modal.dataset.ticker

        let tickersList = JSON.parse(document.querySelector('.x-tickers-list').dataset.tickers)
        let currentIndex = tickersList.indexOf(ticker)
        let nextTicker = tickersList[down ? currentIndex - 1 : currentIndex + 1]
        if (nextTicker) {
          renderChart(nextTicker)
        }
      } else if (e.target.matches('#show-levels')) {
        renderChart(currentChartTicker)
      }
    })

    chartModal.addEventListener("change", e => {
      if (e.target.matches('#chart-period')) {
        renderChart(currentChartTicker)
      }
    })
  }

})

let chart = null
let volumeChart = null
let currentChartTicker = null

function renderChart(ticker, date) {
  date = document.querySelector('#chart-period').value
  fetch(`/instruments/${ticker}/candles?since=${date}`, { headers: { 'Content-Type': 'application/json' } }).then(response => response.json()).then(response => {
    document.querySelector('#chart-modal').dataset.ticker = ticker
    document.querySelector('#chart-modal .tv-link').href = response.trading_view_url
    document.querySelector('#chart-modal .modal-title').innerText = response.name
    document.querySelector('#chart-details').innerHTML = response.details_html

    currentChartTicker = ticker
    let showLevels = document.querySelector('#show-levels').checked

    const Y_LABELS_WIDTH = 80

    if (chart) chart.destroy()
    chart = new ApexCharts(document.querySelector("#the-chart"), {
      series: [
        {
          type: 'candlestick',
          name: 'candles',
          data: response.candles.map( ({ date, ohlc }) => [ date, ohlc ] )
        },
        ... (
          showLevels ?
            response.levels.map(level => ({  type: 'line', name: level.value, data: level.row })) :
            []
        )
      ],
      chart: {
        type: showLevels ? 'line' : 'candlestick',
        height: 380,
        toolbar: { autoSelected: 'pan' },
        animations: { enabled: false },
        id: 'candles',
        group: 'main',
      },
      stroke: {
       width: Array(20).fill(1),
       curve: 'straight'
      },
      colors: ['#f00', ...Array(20).fill('#00f')],
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
      // tooltip: {
      //   shared: true,
      //   custom: [
      //     ({seriesIndex, dataPointIndex, w}) => {
      //       // return w.globals.series[seriesIndex][dataPointIndex]
      //       try {
      //         let o = w.globals.seriesCandleO[seriesIndex][dataPointIndex]
      //         let h = w.globals.seriesCandleH[seriesIndex][dataPointIndex]
      //         let l = w.globals.seriesCandleL[seriesIndex][dataPointIndex]
      //         let c = w.globals.seriesCandleC[seriesIndex][dataPointIndex]
      //         return `Open: ${o}\nHigh: ${h}\nLow: ${l}\nClose: ${c}\n`
      //       } catch {
      //       }
      //     }
      //   ]
      // },

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
        height: 140,
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
