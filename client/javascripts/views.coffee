class Weather.Views.Chart extends Backbone.View
  template: 'chart'

  events:
    "click .next": "nextDate"
    "click .prev": "prevDate"

  initialize: ->
    @collection.on "reset", @render, this
    @collection.on "append", @appendPoint, this

    # @current_view = new Weather.Views.Current

  serialize: ->
    date = @collection.currentDate()
    day: date.toLocaleDateString()

  appendPoint: (data) ->
    if @chart
      date = new Date(data.created_at)
      @chart.get("#{data.station_id}temp").addPoint([date.getTime(), data.temp], false)
      @chart.get("#{data.station_id}hum").addPoint([date.getTime(), data.hum], false)
      @chart.redraw()

  beforeRender: ->
    @$('.loader').hide()
    # @$('.current').html @current_view.render().el

  afterRender: ->
    @_renderDatePicker @collection.currentDate()
    @_renderChart()

  nextDate: ->
    @$('.loader').show()
    @collection.nextDate()

  prevDate: ->
    @$('.loader').show()
    @collection.prevDate()

  _renderDatePicker: (date)->
    @$('.datepick').attr('data-date-format', 'dd-mm-yyyy')
    dateString = "#{date.getDate()}-#{date.getMonth() + 1}-#{date.getFullYear()}"
    @$('.datepick').attr('data-date', dateString)
    picker = @$('.datepick')
    picker.datepicker()
      .on('changeDate', (ev) =>
        picker.datepicker('hide')
        @$('.loader').show()
        @collection.setDate(ev.date)
      )

  _renderChart: ->
    @chart.destroy() if @chart
    @chart = new Highcharts.Chart
      chart:
        renderTo: 'chart-container'
      title:
        text: ''
      yAxis: [
        {
          title:
            text: 'Temperature (C)'
          min: -20
          max: 30
        },
        {
          title:
            text: 'Humidity (%)'
          opposite: true
          min: 0
          max: 100
        }
      ]
      xAxis:
        type: "datetime"

      series: @_dataForChart()

  _dataForChart: ->
    series = []
    @collection.each (station)->
      name = station.get("name")
      dates = station.getDates()
      temps = station.getTemperatures()
      hums = station.getHumidities()

      tempSeries = for i in [0...dates.length]
        a[i] for a in [dates, temps]

      humSeries = for i in [0...dates.length]
        a[i] for a in [dates, hums]

      series.push {id: "#{station.id}temp", name: "#{name} Temperature",data: tempSeries}
      series.push {id: "#{station.id}hum", name: "#{name} Humidity",data:humSeries, yAxis:1}
    series

  cleanup: ->
    @collection.off null, null, this
    @chart.destroy() if @chart

class Weather.Views.Current extends Backbone.View
  template: 'current'

  initialize: ->
    Weather.Globals.notifier = Weather.Globals.notifier || new Weather.Events.Notifier
    @notifier = Weather.Globals.notifier
    @notifier.on "notifier:data", @newData, this
    @data = 10

  newData: (data)->
    console.log data
    # @current = data.message

  render: ->
    console.log "Rendering #{@data}"
    html = @template({current: @data})
    @$el.html(html)
    this

class Weather.Views.ACSettings extends Backbone.View
  template: 'ac_settings'

  events:
    'click .btn.on': 'on'
    'click .btn.off': 'off'

  initialize: ->
    console.log "AC settings"
    # Pusher.channel_auth_transport = 'jsonp'
    # Pusher.channel_auth_endpoint = 'http://weather-logger.dev/pusher/auth'
    # @pusher = new Pusher('aaf8a36f8f5c57b42051')
    # # @channel = @pusher.subscribe("arduino")
    # @presence = @pusher.subscribe("presence-arduino")

    # @presence.bind 'pusher:subscription_succeeded', (members)->
    #   console.log members.count
    #   members.each (member)->
    #     console.log member

    # @presence.bind 'pusher:subscription_error', ->
    #   console.log 'Subsrciption Error'
  serialize: ->
    test: "test"

  _sendPusher: (data) ->
    $.ajax
      url: "http://weather-logger.dev/pusher/send"
      data: data
      crossDomain: true
      dataType: 'jsonp'
      type: 'POST'

  _getTime: ->
    timeStr = $("input#time").val()
    [hour, sec] = timeStr.split(':')
    parseInt(hour) * 3600 + parseInt(sec) * 60

  on: ->
    # @channel.trigger("client-led-on")
    @_sendPusher(event:'on', time:@_getTime())

  off: ->
    # @channel.trigger("client-led-off")
    @_sendPusher(event:'off', time:'Test')

class Weather.Views.StreamsView extends Backbone.View

  initialize: ->
    @collection = new Weather.Collections.Streams
    @collection.fetch()
    @collection.on "reset", @_createViews, this
    @views = []

  _createViews: ->
    models = @collection.filter (model)->
      model.get("name") in ["power"]
    @views.push new Weather.Views.ChartView(models: models)

    models = @collection.filter (model)->
      model.get("name") in ["Wh", "temp", "temp2"]
    @views.push new Weather.Views.ChartView(models: models)
    @render()

  beforeRender: ->
    _.each @views, (view)=>
      @insertView(view)

class Weather.Views.ChartView extends Backbone.View
  template: 'stream'
  className: 'stream row'

  initialize: (options)->
    @models = options.models
    @_reloadModels()
    # @currentViews = []
    _.each(@models, (model)->
      @insertView('.live-values', new Weather.Views.CurrentValueView(model: model)).render()
    ,this)

  _reloadModels: ->
    @chart.showLoading() if @chart
    _.each @models, (model)=>
      model.fetch()
      model.on "change", @_addChartSeries, this
      model.on "change:value", @_addNewValue, this

  cleanup: ->
    _.each @models, (model)=>
      model.off null, null, this
    @chart.destroy() if @chart

  _addNewValue: (data, model)->
    console.log "Data received for #{model.get("name")}"
    date = new Date(data.created_at)
    series = @chart.get(model.get("name"))
    if series
      series.addPoint([date.getTime(), data.value], false)
      @chart.redraw()

  _addChartSeries: (model)->
    @chart.hideLoading()
    name = model.get "name"
    @chart.addSeries
      id: name
      name: name
      data: model.getSeriesData()
      type: if name is "Wh" then "bar" else if name is "power" then "line" else "spline"
      pointWidth: 20 if name is "Wh"
      yAxis: 1 if name in ["temp", "temp2"]
      zIndex: if name is "Wh" then 0 else 1

        # pointInterval: 24 * 3600 * 1000

  _getYAxis: ->
    axis = []
    axis.push
      title:
        text: "Watts"

    if @models.length > 1
      axis.push
        title:
          text: "Temperature"
        min: -30
        max: 30
        opposite: true
    return axis

  _getTitle: ->
    if @models.length > 1
      return "Temperatures and Power Consumption"
    else
      return "Current Power Consumption"


  afterRender: ->
    console.log "Create chart"
    @chart.destroy() if @chart
    @chart = new Highcharts.Chart
      chart:
        renderTo: @$('.chart')[0]
      credits:
        enabled: false
      title:
        text: @_getTitle()
      xAxis:
        type: 'datetime'
      plotOptions:
        series:
          marker:
            enabled: false
      legend:
        enabled: false
      yAxis: @_getYAxis()

    @chart.showLoading()

  class Weather.Views.CurrentValueView extends Backbone.View
    tagName: 'li'
    template: 'current'

    initialize: ->
      @model.on "change", @render, this
      @model.on "change:value", @render, this

    cleanup: ->
      @model.off null, null, this

    serialize: ->
      current = _.last(@model.get("values")).value if @model.get 'values'
      {current: current || 0, unit: @_getUnit(@model.get("name"))}

    _getUnit: (text)->
      switch text
        when "Wh" then "Wh"
        when "temp" then "℃"
        when "temp2" then "℃"
        when "power" then "W"
