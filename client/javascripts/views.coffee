class Weather.Views.Chart extends Backbone.View
  el: 'body'
  template: JST['main']

  events:
    "click .next": "nextDate"
    "click .prev": "prevDate"

  initialize: ->
    @collection.on "reset", @render, this
    @collection.on "append", @appendPoint, this

    @current_view = new Weather.Views.Current

    Highcharts.setOptions
      global:
        useUTC: false

  appendPoint: (data) ->
    if @chart
      date = new Date(data.created_at)
      @chart.get("#{data.station_id}temp").addPoint([date.getTime(), data.temp], false)
      @chart.get("#{data.station_id}hum").addPoint([date.getTime(), data.hum], false)
      @chart.redraw()

  render: ->
    @$('.loader').hide()
    date = @collection.currentDate()
    @$el.html(@template({day: date.toLocaleDateString()}))
    @$('.current').html @current_view.render().el

    @_renderDatePicker(date)
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


class Weather.Views.Current extends Backbone.View
  template: JST['current']

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


