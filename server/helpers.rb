class App < Sinatra::Base
  App.helpers do
    def haml_partial(page, options={})
      haml page, options.merge!(:layout => false)
    end

    def erb_partial(page, options={})
      erb page, options.merge!(:layout => false)
    end

    def json(body_hash, status=200, headers={})
      body = if params[:readable]
        JSON.pretty_generate(body_hash)
      else
        body_hash.to_json
      end
      halt status, headers.merge({'Content-Type' => 'application/json'}), body
    end
  end

  def today
    today = Time.now
    Time.new(today.year, today.month, today.day)
  end

  def toNumber(value)
    if value.index('.')
      value.to_f
    else
      value.to_i
    end
  end

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

end
