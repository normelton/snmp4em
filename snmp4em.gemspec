# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "snmp4em"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Norman Elton"]
  s.date = "2012-02-23"
  s.description = "A high-performance SNMP engine built on EventMachine and Ruby-SNMP"
  s.email = "normelton@gmail.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = Dir["lib/**/*.rb"] + Dir["bin/*"]
  s.homepage = "http://github.com/normelton/snmp4em"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Snmp4em", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "snmp4em"
  s.rubygems_version = "1.8.16"
  s.summary = "A high-performance SNMP engine built on EventMachine and Ruby-SNMP"
  s.add_runtime_dependency 'snmp', '>= 1.0.2'
  s.add_runtime_dependency 'eventmachine', '>= 1.0.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  
end
