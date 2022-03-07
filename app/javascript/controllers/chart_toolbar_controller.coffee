import { Controller } from "@hotwired/stimulus"

export default class extends Controller
  connect: ->
    @charts = {}
    @currentBarSpacing = 2
    @chartHeight = 0
    
  
  zoom: (e) ->
    # e.preventDefault()
    # e.target.blur()
    # console.log e

    # target.blur()
    # step = Number(target.dataset.value)
    # @currentBarSpacing = @currentBarSpacing + step
    # for ticker, chart of charts
    #   chart.setBarSpacing @currentBarSpacing # current = chart.timeScale().options().barSpacing
    # updateChartSettings reload: false
  # 
  # togleTimeScale: (e) ->
  #   for ticker, { chart } of @charts
  #     chart.applyOptions timeScale: { visible: e.target.checked }
  #   @updateChartSettings reload: false
  # 
  # togglePriceScale: (e) ->
  #   for ticker, { chart } of @charts
  #     chart.applyOptions priceScale: { visible: e.target.checked }
  #   @updateChartSettings reload: false
  # 
  # toggleWheelScaling: (e) ->
  #   for ticker, { chart } of @charts
  #     chart.applyOptions handleScale: { mouseWheel: e.target.checked }
  #   @updateChartSettings reload: false   
  # 
  # toggleLevelLabels: (e) ->
  #   @updateChartSettings reload: true   
  # 
  # toggleLevels: (e) ->
  #   @updateChartSettings reload: true
  # 
  # gotoEnd: ->
  #   for ticker, { chart } of @charts
  #     chart.timeScale().scrollToRealTime() 
  # 
  # gotoDown: -> 
  #   window.scrollBy 0, @chartHeight * 2
  # 
  # gotoUp: ->
  #   window.scrollBy 0, -(@chartHeight * 2)
  # 
  # openSettings: ->
  #   modal = new Modal document.getElementById 'chart-settings-modal'
  #   modal.show()        
