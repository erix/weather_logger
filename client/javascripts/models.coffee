class Weather.Models.Station extends Backbone.Model
  getDates: ->
    dates = for dateString in _.pluck(@get("readings"), "created_at")
      date = new Date(dateString)
      date.getTime()

  getTemperatures: ->
      _.pluck(@get("readings"),"temp")

  getHumidities: ->
      _.pluck(@get("readings"),"hum")

class Weather.Models.Stream extends Backbone.Model
  initialize: ->
    Weather.Globals.notifier.channel.bind "stream:#{@get("name")}", @newData

  newData: (data)=>
    values = @get("values")
    values.push data if values
    @trigger "change:value", data, this

  getSeriesData: ->
    values = _.pluck(@get("values"), "value")
    dates = for dateString in _.pluck(@get("values"), "created_at")
      date = new Date(dateString)
      date.getTime()

    series = for i in [0...dates.length]
      a[i] for a in [dates, values]





