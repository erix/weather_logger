class Weather.Routers.Router extends Backbone.Router
  routes:
    "": "redirectToToday"
    ":year/:month/:day": 'showChart'
    "acsettings": 'showACSettings'

  initialize: ->
    @main = new Backbone.Layout
      template: "main"
    $("body").empty().append(@main.el);
    @main.render()

  redirectToToday: ->
    #TODO: refactor
    today = new Date
    Backbone.history.navigate("#{today.getFullYear()}/#{today.getMonth() + 1}/#{today.getDate()}", false)
    @stations = Weather.Globals.stations || new Weather.Collections.Stations
    @chartView = new Weather.Views.Chart(collection:@stations)
    @main.setView(".content", @chartView).render()

  showChart: (year, month, day)->
    @stations ?= new Weather.Collections.Stations
    @chartView ?= new Weather.Views.Chart(collection:@stations)
    date = new Date parseInt(year), parseInt(month)-1, parseInt(day)
    @main.setView(".content", @chartView).render()
    @stations.setDate date

  showACSettings: ->
    @main.setView(".content", new Weather.Views.ACSettings).render()

