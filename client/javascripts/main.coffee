window.Weather = window.Weather || {
  Collections: {}
  Models: {}
  Views: {}
  Routers: {}
  Events: {}
  Globals: {}
  init: ->
    new Weather.Routers.Router
    Backbone.history.start()
}

$ ->
  window.Weather.init()
