class Weather.Events.Notifier
  constructor: ->
    console.log "Notifier"
    _.extend(this, Backbone.Events)
    @pusher = new Pusher('aaf8a36f8f5c57b42051');
    @channel = @pusher.subscribe('weather')
    @channel.bind "reading", (data)=>
      @trigger "notifier:data", data


