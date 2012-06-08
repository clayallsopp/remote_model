# -*- encoding: utf-8 -*-
require File.expand_path('../lib/remote_model/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "remote_model"
  s.version     = RemoteModel::VERSION
  s.authors     = ["Clay Allsopp"]
  s.email       = ["clay.allsopp@gmail.com"]
  s.homepage    = "https://github.com/clayallsopp/remote_model"
  s.summary     = "JSON API <-> NSObject via RubyMotion"
  s.description = "JSON API <-> NSObject via RubyMotion. Create REST-aware models."

  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "bubble-wrap"
  s.add_development_dependency 'rake'
end