require "remote_model/version"
require 'bubble-wrap'
require "motion_support/inflector"

Dir.glob(File.join(File.dirname(__FILE__), 'remote_model/*.rb')).each do |file|
  BW.require file
end
