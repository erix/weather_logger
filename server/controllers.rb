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

  def parse_streams(stream_str, &block)
    stream_str.each do |line|
      line = line.chomp
      unless line.blank?
        key, value = line.chomp.split ","
        yield key, value
      end
    end
    
  end

  get "/" do
    @message = "Weather"
    @stations = fetch_for_date(today)
    haml :index
  end

  post "/streams" do
    # can post multiple streams at once
    # raw = request.env["rack.input"].read
    # puts raw
    parse_streams(request.body) do |key, value|
      stream = DataStream.find_or_create_by(name: key)
      dbValue = Value.new(value: value)
      stream.values << dbValue
      Pusher['weather'].trigger("stream:#{key}", {:value => toNumber(dbValue.value), :created_at => dbValue.created_at}) unless settings.environment == :test
    end
  end

  get "/streams" do
    content_type :json
    @streams = DataStream.all
    render :rabl, :streams, :format => :json
  end

  get "/streams/:id" do |id|
    content_type :json
    # @stream = DataStream.where(:values => {:created_at.gt => Time.now - 3600}).find(id)
    @stream = DataStream.find(id)
    if @stream
      @stream.values = @stream.values.where(:created_at.gt => Time.now - (24 * 3600))
      render :rabl, :stream, :format => :json
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
  post "/pusher/streams" do
    parse_streams(request.body) do |key, value|
      Pusher['weather'].trigger("stream:#{key}", {:value => toNumber(value), :created_at => Time.now}) unless settings.environment == :test
    end
  end

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
