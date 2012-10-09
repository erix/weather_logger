window.Weather = {
  Collections: {}
  Models: {}
  Views: {}
  Routers: {}
}

class Weather.Collections.Readings extends Backbone.Collection
  url: '/stations/'

  initialize: (options)->
    @st_model = "1234"

  setDate: (date) ->
    console.log "SetDate"
    [year, month, day] = [date.getFullYear(), date.getMonth()+1, date.getDate()]
    [@year, @month, @day] = [year, month, day]
    @url = "/stations/#{@st_model}/#{year}/#{month}/#{day}"
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
    console.log "View create", @collection
    @collection.on "reset", @render, this

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
    dates = for dateString in @collection.pluck("created_at")
      date = new Date(dateString)
      date.getTime()

    temps = @collection.pluck("temp")
    hums = @collection.pluck("hum")

    tempSeries = for i in [0...dates.length]
      a[i] for a in [dates, temps]

    humSeries = for i in [0...dates.length]
      a[i] for a in [dates, hums]

    chart = new Highcharts.Chart
      chart:
        renderTo: 'chart'
      title:
        text: ''
      yAxis: [
        {
          title:
            text: 'Tempearture (C)'
        },
        {
          title:
            text: 'Humidity (%)'
          opposite: true
        }
      ]
      xAxis:
        type: "datetime"
      series: [
        {
          name: "Temperature"
          data: tempSeries
        },
        {
          name: 'Humidity'
          data: humSeries
          yAxis: 1
        }
      ]


class Weather.Routers.Router extends Backbone.Router
  routes:
    "": "redirectToToday"
    "stations/:model_id/:year/:month/:day": 'showChart'

  initialize: ->
    @station = new Weather.Collections.Readings
    @view = new Weather.Views.Chart(collection:@station)

  redirectToToday: ->
    # today = new Date
    today = new Date 2012,9,1
    Backbone.history.navigate("stations/1a3d/#{today.getFullYear()}/#{today.getMonth() + 1}/#{today.getDate()}", true)

  showChart: (model_id , year, month, day)->
    console.log "Router"
    date = new Date parseInt(year), parseInt(month)-1, parseInt(day)
    @station.setDate date

$ ->
  r = new Weather.Routers.Router
  Backbone.history.start()
