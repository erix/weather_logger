class Station
  include Mongoid::Document

  field :model
  field :description
  has_many :readings
end

class Reading
  include Mongoid::Document

  field :temp, type: Float
  field :hum, type: Integer
  field :created_at, type: Time, default: ->{ Time.now }

  belongs_to :station
end

class DataStream
  include Mongoid::Document

  field :name
  field :description

  embeds_many :values
end

class Value
  include Mongoid::Document
  embedded_in :datastream

  field :value
  field :created_at, type: Time, default: ->{ Time.now }
end

class App < Sinatra::Base

  def valid?(message)
    a = message.scan(/../)
    checksum = a[8].hex

    sum = 0
    message[0..-5].each_char {|c| sum = sum + c.hex}
    ((sum - 10) & 0xFF) == checksum
  end

  #parses OSV2 report
  #http://www.mattlary.com/2012/06/23/weather-station-project/
  def parseReport(report)
    # 0: model
    # 1: sign
    # 2: tens
    # 3: ones
    # 4: tenths
    # 5: humidity one
    # 6: humidity tens

    return nil if not valid?(report)

    a = report.unpack('a4@13h@10hh@8h@12h@15h')
    sign = a[1].eql?("0") ? "+" : "-"

    parsed = {
      station: a[0].downcase,
      reading: {
        temp: "%s%s%s.%s" % [sign, a[2..4]].flatten,
        hum: "#{a[6]}#{a[5]}".to_i
      }
    }

    return parsed
  end

  def fetch_station_for_date(station, date)
    if station
      range = Range.new(date, date + 86400) #range is +1 day
      readings = station.readings.where(created_at: range)
      readings
    else
      nil
    end
  end

  def fetch_for_date(date)
    response = []
    Station.each do |station|
      response << {id: station.id, name: station.description, readings: fetch_station_for_date(station, date)}
    end
    response
  end

  get "/" do
    @message = "Weather"
    @stations = fetch_for_date(today)
    haml :index
  end

  post "/streams" do
    # can post multiple streams at once
    request.body.each_line do |line|
      key, value = line.chomp.split ","
      stream = DataStream.find_or_create_by(name: key)
      stream.values << Value.new(value: value)
    end
  end

  get "/streams/:name" do |name|
    content_type :json
    stream = DataStream.find_by(name: name)
    if stream
      stream.to_json
    else
      status 404
    end
  end

  get "/stations/:model" do |model|
    content_type :json
    station = Station.find_by(model:model)
    readings = fetch_station_for_date(station, today)
    if readings
      readings.to_json
    else
      status 404
    end
  end

  get "/stations/:model/:year/:month/:day" do |model, year, month, day|
    content_type :json
    date = Time.new(year.to_i, month.to_i, day.to_i)
    station = Station.find_by(model:model)
    readings = fetch_station_for_date(station, date)
    if readings
      readings.to_json
    else
      status 404
    end
  end

  get "/:year/:month/:day" do |year, month, day|
    content_type :json
    date = Time.new(year.to_i, month.to_i, day.to_i)
    fetch_for_date(date).to_json
  end

  get "/save" do
    parsed = parseReport(params[:report])

    if not parsed
      status 500
      return "Invalid data"
    end

    # p parsed

    station = Station.find_by(model:parsed[:station]) || Station.create(model:parsed[:station], description:"Unknown")
    if station
      reading = Reading.new parsed[:reading]
      station.readings << reading
      Pusher['weather'].trigger('reading', {:message => reading.attributes}) unless settings.environment == :test
      "Station: temperature #{parsed[:reading][:temp]} - humidity: #{parsed[:reading][:hum]}%"
    else
      status 500
      "Cannot create DB entry"
    end
  end

  #Pusher endpoints
  get "/pusher/send" do
    puts "Pusher #{params}"
    Pusher['arduino'].trigger(params[:event], :time => params[:time])
  end


  get "/pusher/auth" do
    puts "Authenticate #{params}"
    auth = Pusher[params[:channel_name]].authenticate(params[:socket_id], :user_id => "1234")
    "#{params[:callback]}(#{auth.to_json})"
  end
end
