require "spec_helper.rb"
# require_relative "../server/controllers.rb"

describe "Weather service" do

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
end
