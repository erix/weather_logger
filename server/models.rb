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
end

class Value
  include Mongoid::Document
  belongs_to :data_stream

  field :value
  field :created_at, type: Time, default: ->{ Time.now }
end

