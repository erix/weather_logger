window.Weather = {
  Collections: {}
  Models: {}
  Views: {}
  Routers: {}
}

class Weather.Collections.Readings extends Backbone.Collection
  url: '/stations/'

  initialize: (options)->
    @st_model = "1a3d"

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
    Morris.Line
      element: 'chart'
      data: @collection.toJSON()
      xkey: 'created_at'
      ykeys: ['temp', 'hum']
      xLabels: 'hour'
      labels: ['Temperature', 'Humidity']
      lineSize: 1
      pointSize: 2
      hideHover: true



class Weather.Routers.Router extends Backbone.Router
  routes:
    "": "redirectToToday"
    "stations/:model_id": 'showChart'

  redirectToToday: ->
    Backbone.history.navigate("stations/1a3d", true)

  showChart: (model_id) ->
    console.log "Router"
    station = new Weather.Collections.Readings
    view = new Weather.Views.Chart(collection:station)
    station.setDate(new Date(2012,9,1))

$ ->
  r = new Weather.Routers.Router
  Backbone.history.start()
