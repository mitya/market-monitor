import ApexCharts from 'apexcharts'

document.addEventListener("turbolinks:load", () => {
  let comparisionChart = null

  if (window.PageData) {
    let comparisionData = PageData.comparision
    console.log(comparisionData)
    console.log(PageData.dates)

    if (comparisionChart) comparisionChart.destroy()

    comparisionChart = new ApexCharts(document.querySelector("#comparision-chart"), {
      series: comparisionData,
      chart: { type: 'line', height: 400 },
      // stroke: {
      //  width: Array(20).fill(1),
      //  curve: 'straight'
      // },
      // colors: ['#f00', ...Array(20).fill('#00f')],
      // title: {
      //   text: `Comparision`,
      //   align: 'left'
      // },
      xaxis: {
        categories: PageData.dates,
        type: 'datetime',
        // labels: { format: 'MMM dd', }
      },
    })

    comparisionChart.render()
  }
})
