import consumer from "./consumer"

const syncChannel = consumer.subscriptions.create("SyncChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    console.log('SyncChannel received data', data)
    if (data.reason == 'prices' && window.DashboardPeriod == '') {
      location.reload()
    } else if (data.reason == 'candles') {
      document.dispatchEvent(new Event('chart-reload-data'))
    } else if (data.reason == 'reload_chart') {
      if ($qs('.charts-page')) {
        location.reload()
      }
    }
  },

  setChartTicker(ticker) {
    this.perform("set_chart_ticker", { ticker: ticker })
  },
});

window.syncChannel = syncChannel
