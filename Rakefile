task :start do
  sh %{rerun --dir server -- foreman start}
end

task :guard do
  require 'guard'
  Rake::Task["assets:compile_all"].invoke
  ::Guard.start
end

task :test do
  require 'jasmine'
  # custom config directory hack
  Jasmine::Config.class_eval do
    def simple_config_file
      File.join(project_root, 'config/jasmine.yml')
    end
  end

  load 'jasmine/tasks/jasmine.rake'
  Rake::Task["assets:compile_all"].invoke
  Rake::Task["jasmine"].invoke
end

desc 'Creates seed data to DB'
task :seed do
  require './server/application.rb'
  Station.create(model:"1a2d", description:"Inside sensor")
  Station.create(model:"1a3d", description:"Outside sensor")
end

namespace :db do
  desc 'Clears DB values'
  task :clear do
    require './server/application.rb'
    puts DataStream.all.to_a.inspect
    DataStream.all.each do |stream|
      puts "Clearing #{stream.name}"
      stream.values.where(:created_at.lt => Time.now - 24*2600).each {|v| v.delete} if stream != "Wh"
    end
  end
end

namespace :assets do
  desc 'compile sprockets to static files for testing purposes'

  task :compile_all do
    require 'colored'
    require './lib/sprockets_environment_builder'
    %w{javascripts stylesheets specs}.each do |asset|
      Rake::Task["assets:compile_#{asset}"].invoke
    end
    puts "Finished asset precompilation".blue
  end

  task :compile_javascripts do
    compile_asset('client/public/.compiled', 'application.js', :development)
  end

  task :compile_stylesheets do
    compile_asset('client/public/.compiled', 'application.css', :development)
  end

  task :compile_specs do
    compile_asset('spec/.compiled', 'spec.js', :test)
  end
end

def compile_asset(parent_dir, filename, environment)
  require 'colored'
  sprockets = SprocketsEnvironmentBuilder.build(environment)
  FileUtils.mkdir_p(parent_dir)
  sprockets.find_asset(filename).write_to(File.join(parent_dir, filename))
  puts "Compiled: #{filename.green}"
end
