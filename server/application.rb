require 'sinatra'
require 'sinatra/contrib'
require 'json'
require "mongoid"
require 'pusher'
require 'rabl'
require "pp"

# File.readlines(".env").each do |line|
#   key, value = line.split("=")
#   ENV[key] = value
# end


%w[lib server].each do |dir|
  Dir.glob("./#{dir}/*.rb").each do |relative_path|
    p relative_path
    require relative_path  unless relative_path == "./server/application.rb"
  end
end

Pusher.app_id = ENV['PUSHER_ID']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']

set :sprockets, SprocketsEnvironmentBuilder.build(ENV['RACK_ENV'] || 'development')

Mongoid.load!("./config/mongoid.yml")

Rabl.configure do |config|
  config.include_json_root = false
  config.include_child_root = false
end

configure :production do
  require 'newrelic_rpm'
  # Ensure the agent is started using Unicorn
  # This is needed when using Unicorn and preload_app is not set to true.
  # See http://support.newrelic.com/kb/troubleshooting/unicorn-no-data
  NewRelic::Agent.after_fork(:force_reconnect => true) if defined? Unicorn
end

class App < Sinatra::Base
  Rabl.register!
  register Sinatra::Contrib
  set :root, File.expand_path(".")
  set :public_folder, Proc.new { File.join(root, "client/public") }
  set :views, Proc.new { File.join(root, "client/views") }
end
