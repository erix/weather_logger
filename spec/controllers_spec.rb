require "spec_helper.rb"
# require_relative "../server/controllers.rb"

describe "Weather service" do

  describe "Oregon Scientific interface" do

    it "should save a report" do
      get "/save?report=1A2D105F112230453776" do
        last_response.should be_ok
      end
    end

    it "should discard wrong report" do
      get "/save?report=1A2D105F112230453876" do
        last_response.status.should equal(500)
      end
    end

    it "should return readings for a given station" do
      st = Station.create(model:"1234")
      reading = %([{"temp":10.0, "hum":20}])
      st.readings << Reading.new(temp:10.0, hum:20)

      get "/stations/1234" do
        last_response.should be_ok
        last_response.body.should be_json_eql(reading).excluding("created_at", "_id", "_type", "station_id")
      end
    end

    it "should not return readings for a not existing station" do
      get "/stations/1234" do
        last_response.status.should equal(404)
      end
    end

    it "should return readings for a given station and given date" do
      Station.create(model:'1234')
      get "/stations/1234/2012/10/2" do
        last_response.should be_ok
      end
    end

    it "should return all station readings for a given date" do
      Station.create(model:'1234', description:'Test1').readings << Reading.new(temp:10.0, hum:20)
      Station.create(model:'1235', description:'Test2').readings << Reading.new(temp:11.0, hum:21)

      expected = <<END
[
  {
    "name":"Test1",
    "readings": [
      {"temp":10.0, "hum":20}
    ]
  },
  {
    "name":"Test2",
    "readings":[
      {"temp":11.0, "hum":21}
    ]
  }
]
END

      todayURL = "/#{Time.now.year}/#{Time.now.month}/#{Time.now.day}"
      get todayURL do
        last_response.should be_ok
        last_response.body.should be_json_eql(expected).excluding("_id", "station_id", "created_at")
      end
    end
  end

  describe "Cosm interface" do
    it "can post a data stream" do
      post "/streams", "power,1234"
      last_response.should be_ok
    end

    it "should post multiple streams at once" do
      post "/streams", "power,1234\ntemp,12\nhum,34"
      last_response.should be_ok
    end

    it "should create new stream to DB" do
      data_stream = "power"
      post "/streams", "#{data_stream},1234"
      DataStream.find_by(name: data_stream).should_not be_nil
    end

    it "should add new value to an existing stream" do
      data_stream = "power"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: "4567")

      post "/streams", "#{data_stream},1234"
      stream = DataStream.find_by(name: data_stream)
      stream.values.size.should == 2
    end

    it "should create multiple streams to DB" do
      data_stream1 = "power"
      value1 = "1234"
      data_stream2 = "temp"
      value2 = "34"

      post "/streams", "#{data_stream1},#{value1}\n#{data_stream2},#{value2}"

      stream1 = DataStream.find_by(name: data_stream1)
      stream1.should_not be_nil
      stream1.values.first.value.should == value1

      stream2 = DataStream.find_by(name: data_stream2)
      stream2.should_not be_nil
      stream2.values.first.value.should == value2
    end

    it "should return the requested data stream" do
      stream = DataStream.create(name: "power")
      get "/streams/#{stream.id}" do
        last_response.should be_ok
      end
    end

    it "should not return data for non existent stream" do
      get "/streams/invalid" do
        # puts last_response.body
        last_response.status.should == 404
      end
    end

    it "should return all available streams" do
      stream1 = "stream1"
      stream2 = "stream2"
      DataStream.create(name: stream1, description: "test")
      DataStream.create(name: stream2, description: "test")

      get "/streams" do
        last_response.body.should be_json_eql(%([{"name":"#{stream1}", "description":"test"}, {"name":"#{stream2}", "description":"test"}]))
      end
    end

    it "should return values for the requested stream" do
      data_stream = "power"
      value1 = "345"
      value2 = "7.45"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: value1) << Value.new(value: value2)
      expected = %({"name":"#{data_stream}", "values":[{"value":#{value1}}, {"value": #{value2}}]})

      get "/streams/#{stream.id}" do
        last_response.should be_ok
        # puts last_response.body
        last_response.body.should be_json_eql(expected).excluding(:_id, :created_at, :description)
      end
    end

    it "should return only 1 day old data" do
      data_stream = "test"
      value1 = "345"
      value2 = "7.45"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: value1, created_at: Time.now - (25 * 3600)) << Value.new(value: value2)
      expected = %({"name":"#{data_stream}", "values":[{"value": #{value2}}]})

      get "/streams/#{stream.id}" do
        last_response.should be_ok
        # puts last_response.body
        last_response.body.should be_json_eql(expected).excluding(:_id, :created_at, :description)
      end
    end

    it "should return data for the given date" do
      data_stream = "test"
      value1 = "345"
      value2 = "7.45"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: value1, created_at: Time.new(2012,12,7)) << Value.new(value: value2)
      expected = %({"name":"#{data_stream}", "values":[{"value": #{value2}}]})

      get "/streams/#{stream.id}/2012/12/8" do
        last_response.should be_ok
        # puts last_response.body
        last_response.body.should be_json_eql(expected).excluding(:_id, :created_at, :description)
      end
    end

    it "should delete old entries after receiving a new" do
      validity = 7200
      data_stream = "power"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: "12", created_at: Time.now - (validity + 1))
      post "/streams", "#{data_stream},1234"
      last_response.should be_ok
      stream = DataStream.find_by(name: data_stream)
      stream.values.size.should == 1
    end

    it "should not delete old entries for not power streams" do
      validity = 7200
      data_stream = "test"
      stream = DataStream.create(name: data_stream)
      stream.values << Value.new(value: "12", created_at: Time.now - (validity + 1))
      post "/streams", "#{data_stream},1234"
      last_response.should be_ok
      stream = DataStream.find_by(name: data_stream)
      stream.values.size.should == 2
    end
  end
end
