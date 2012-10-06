require 'compass'
require 'haml_coffee_assets'
require 'sprockets'
require 'sprockets-sass'
require 'bootstrap-sass'
require 'yui/compressor'
require 'uglifier'

Compass.configuration do |compass|
  compass.http_generated_images_path = "/assets"
  compass.images_dir = "client/images"
end

class SprocketsEnvironmentBuilder
  def self.build(environment = :development)
    environment = environment.to_sym
    sprockets = Sprockets::Environment.new

    sprockets.append_path 'client/javascripts'
    sprockets.append_path 'client/stylesheets'
    sprockets.append_path 'client/images'
    sprockets.append_path 'client/templates'
    sprockets.append_path 'spec/javascripts'

    if [:production, :test].include? environment
      sprockets.css_compressor = YUI::CssCompressor.new
      sprockets.js_compressor = Uglifier.new(mangle: false)
    end

    sprockets
  end
end
