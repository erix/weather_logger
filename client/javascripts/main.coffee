window.Weather = {
  Collections: {}
  Models: {}
  Views: {}
  Routers: {}
  Events: {}
}

class Weather.Events.Notifier
  constructor: ->
    _.extend(this, Backbone.Events)
    @pusher = new Pusher('aaf8a36f8f5c57b42051');
    @channel = @pusher.subscribe('weather')
    @channel.bind "reading", (data)=>
      @trigger "notifier:data", data

class Weather.Models.Station extends Backbone.Model
  getDates: ->
    dates = for dateString in _.pluck(@get("readings"), "created_at")
      date = new Date(dateString)
      date.getTime()

  getTemperatures: ->
      _.pluck(@get("readings"),"temp")

  getHumidities: ->
      _.pluck(@get("readings"),"hum")

class Weather.Collections.Stations extends Backbone.Collection
  model: Weather.Models.Station

  initialize:->
    @notifier = new Weather.Events.Notifier
    @notifier.on "notifier:data", @newData, this

  newData: (data) ->
    station = @get(data.message.station_id)
    station.get("readings").push data.message

  setDate: (date) ->
    [year, month, day] = [date.getFullYear(), date.getMonth()+1, date.getDate()]
    [@year, @month, @day] = [year, month, day]
    @url = "/#{year}/#{month}/#{day}"
    Backbone.history.navigate(@url)
    @fetch()

  currentDate: ->
    new Date(@year, @month - 1, @day)

  nextDate: ->
    @setDate(new Date(@year, @month-1, @day+1))

  prevDate: ->
    @setDate(new Date(@year, @month-1, @day-1))



class Weather.Views.Chart extends Backbone.View
  el: 'body'
  template: JST['main']

  events:
    "click .next": "nextDate"
    "click .prev": "prevDate"

  initialize: ->
    @collection.on "reset", @render, this
    @collection.on "append", @appendPoint, this

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
            text: 'Tempearture (C)'
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



class Weather.Routers.Router extends Backbone.Router
  routes:
    "": "redirectToToday"
    ":year/:month/:day": 'showChart'

  initialize: ->
    @station = new Weather.Collections.Stations
    @view = new Weather.Views.Chart(collection:@station)

  redirectToToday: ->
    today = new Date
    # today = new Date 2012,9,1
    Backbone.history.navigate("#{today.getFullYear()}/#{today.getMonth() + 1}/#{today.getDate()}", true)

  showChart: (year, month, day)->
    date = new Date parseInt(year), parseInt(month)-1, parseInt(day)
    @station.setDate date

$ ->
  r = new Weather.Routers.Router
  Backbone.history.start()
