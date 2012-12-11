object @stream
attributes :id, :name
child @values do
  attribute :created_at
  node :value do |obj|
    valueStr = obj.value
    if valueStr.index('.')
      valueStr.to_f
    else
      valueStr.to_i
    end
  end
end
