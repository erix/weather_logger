Backbone.LayoutManager.configure(
  manage: true

  fetch: (name)->
    return window.JST[name]

  render: (template, context) ->
    return template(context);
)

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

Highcharts.setOptions
      global:
        useUTC: false

$ ->
  window.Weather.init()
