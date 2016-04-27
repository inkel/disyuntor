# -*- coding: utf-8 -*-

require_relative "lib/disyuntor/version"

Gem::Specification.new do |s|
  s.name        = "disyuntor"
  s.version     = Disyuntor::VERSION
  s.summary     = "Circuit Breaker Pattern in Ruby"
  s.description = "Simple implementation of Michael T. Nygard's Circuit Breaker Pattern"
  s.authors     = ["Leandro López"]
  s.email       = ["inkel.ar@gmail.com"]
  s.homepage    = "http://github.com/inkel/disyuntor"
  s.license     = "MIT"

  s.required_ruby_version = '>= 2.0'

  s.files = `git ls-files`.split("\n")

  s.add_development_dependency "minitest", ">= 5.8.4"
end
