#!/usr/bin/env rake
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require "bundler/gem_tasks"
Bundler.setup
Bundler.require

$:.unshift("./lib/")
require './lib/remote_model'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'RemoteModel'
end