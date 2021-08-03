import ApexCharts from 'apexcharts'

document.addEventListener "turbolinks:load", ->
  comparisionChart = null
  if window.PageData
    comparisionData = PageData.comparision
    comparisionChart.destroy() if comparisionChart
    comparisionChart = new ApexCharts document.querySelector("#comparision-chart"),
      series: comparisionData,
      chart: { type: 'line', height: 400 },
      xaxis: { categories: PageData.dates, type: 'datetime' }
    comparisionChart.render()
