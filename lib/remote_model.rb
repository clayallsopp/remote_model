require "remote_model/version"
require "bubble-wrap"

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  Dir.glob(File.join(File.dirname(__FILE__), 'remote_model/*.rb')).each do |file|
    app.files.unshift(file)
  end
end
