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

  has_many :values

  def delete_old_entries(validity)
    old_values = self.values.where(:created_at.lt => Time.now - validity)
    old_values.each { |v| v.delete }
  end
end

class Value
  include Mongoid::Document
  belongs_to :data_stream

  field :value
  field :created_at, type: Time, default: ->{ Time.now }

  after_create :delete_old

  def delete_old
    # clears the DB from old power entries
    # we keep only 2 hours of power entries
    if self.data_stream.name == "power"
      self.data_stream.delete_old_entries(7200) # validity is 2 hour
    end
  end

end

