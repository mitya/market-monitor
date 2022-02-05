import consumer from "./consumer"

consumer.subscriptions.create("SyncChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    console.log('SyncChannel received data', data)
    if (data.reason == 'prices' && window.DashboardPeriod == '') {
      location.reload()
    }
  }
});
