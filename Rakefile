$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'RemoteModelTestSuite'
  # via BubbleWrap
  app.delegate_class = 'TestSuiteDelegate'
  app.files += Dir.glob(File.join(app.project_dir, 'vendor/BubbleWrap/lib/**/*.rb')) + Dir.glob('./lib/**.rb') 
end