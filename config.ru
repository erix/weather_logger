require './server/application'

map '/assets' do
  run settings.sprockets
end

map '/' do
  run App
end
