class Weather.Collections.Stations extends Backbone.Collection
  model: Weather.Models.Station

  initialize:->
    console.log "Stations"
    Weather.Globals.notifier ?= new Weather.Events.Notifier
    @notifier = Weather.Globals.notifier
    @notifier.on "notifier:data", @newData, this
    date = new Date
    @_setDate(date)

  newData: (data) ->
    if @_isToday
      station = @get(data.message.station_id)
      station.get("readings").push data.message
      @trigger "append", data.message

  setDate: (date) ->
    @_setDate(date)
    @url = "/#{@year}/#{@month}/#{@day}"
    Backbone.history.navigate(@url)
    @fetch()

  _setDate: (date)->
    [@year, @month, @day] = [date.getFullYear(), date.getMonth()+1, date.getDate()]

  _isToday: ->
    today = new Date
    currentDate = @currentDate()
    currentDate.getFullYear() is today.getFullYear() and
      currentDate.getMonth is today.getMonth() and
      currentDate.getDate() is today.getDate()

  currentDate: ->
    new Date(@year, @month - 1, @day)

  nextDate: ->
    @setDate(new Date(@year, @month-1, @day+1))

  prevDate: ->
    @setDate(new Date(@year, @month-1, @day-1))

class Weather.Collections.Streams extends Backbone.Collection
  url: "/streams"
  model: Weather.Models.Stream
