window.Weather = window.Weather || {
  Collections: {}
  Models: {}
  Views: {}
  Routers: {}
  Events: {}
  Globals: {}
}

$ ->
  new Weather.Routers.Router
  Backbone.history.start()
