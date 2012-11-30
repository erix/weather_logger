class Weather.Models.Station extends Backbone.Model
  getDates: ->
    dates = for dateString in _.pluck(@get("readings"), "created_at")
      date = new Date(dateString)
      date.getTime()

  getTemperatures: ->
      _.pluck(@get("readings"),"temp")

  getHumidities: ->
      _.pluck(@get("readings"),"hum")



