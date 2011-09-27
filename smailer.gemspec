# -*- encoding: utf-8 -*-
require File.expand_path("../lib/smailer/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "smailer"
  s.version     = Smailer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Dimitar Dimitrov']
  s.email       = ['wireman@gmail.com']
  s.homepage    = "http://github.com/mitio/smailer"
  s.summary     = "A simple newsletter mailer for Rails."
  s.description = "A simple mailer for newsletters with basic campaign management, queue and unsubscribe support. To be used within Rails."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "smailer"

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.add_dependency "mail", "~> 2.2.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
