# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-aws/version"

Gem::Specification.new do |s|
  s.name        = "em-aws"
  s.version     = EventMachine::AWS::VERSION
  s.authors     = ["Stephen Eley"]
  s.email       = ["sfeley@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{EventMachine library for Amazon Web Services}
  s.description = %q{EM-AWS is a generalized wrapper for the various Amazon Web Services SDKs using EventMachine and a callback-based model for handling responses.}

  s.rubyforge_project = "em-aws"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "eventmachine"
  s.add_runtime_dependency "em-http-request"
  s.add_runtime_dependency "nokogiri"
  
  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock"
end
