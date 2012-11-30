class Weather.Routers.Router extends Backbone.Router
  routes:
    "": "redirectToToday"
    ":year/:month/:day": 'showChart'

  initialize: ->
    @stations = Weather.Globals.stations || new Weather.Collection.Stations
    @view = new Weather.Views.Chart(collection:@stations)
    @view.render()

  redirectToToday: ->
    today = new Date
    Backbone.history.navigate("#{today.getFullYear()}/#{today.getMonth() + 1}/#{today.getDate()}", false)

  showChart: (year, month, day)->
    date = new Date parseInt(year), parseInt(month)-1, parseInt(day)
    @stations.setDate date

