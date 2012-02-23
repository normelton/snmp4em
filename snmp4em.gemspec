# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "snmp4em"
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Norman Elton"]
  s.date = "2012-02-23"
  s.description = "A high-performance SNMP engine built on EventMachine and Ruby-SNMP"
  s.email = "normelton@gmail.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "lib/snmp4em.rb", "lib/snmp4em/common_requests.rb", "lib/snmp4em/extensions.rb", "lib/snmp4em/extensions/snmp/integer.rb", "lib/snmp4em/extensions/snmp/ip_address.rb", "lib/snmp4em/extensions/snmp/null.rb", "lib/snmp4em/extensions/snmp/object_id.rb", "lib/snmp4em/extensions/snmp/octet_string.rb", "lib/snmp4em/extensions/snmp/response_error.rb", "lib/snmp4em/handler.rb", "lib/snmp4em/manager.rb", "lib/snmp4em/requests/snmp_get_request.rb", "lib/snmp4em/requests/snmp_getbulk_request.rb", "lib/snmp4em/requests/snmp_getnext_request.rb", "lib/snmp4em/requests/snmp_set_request.rb", "lib/snmp4em/requests/snmp_walk_request.rb", "lib/snmp4em/snmp_request.rb", "lib/snmp4em/snmp_v2c_requests.rb", "snmp4em.gemspec", "Manifest"]
  s.homepage = "http://github.com/normelton/snmp4em"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Snmp4em", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "snmp4em"
  s.rubygems_version = "1.8.16"
  s.summary = "A high-performance SNMP engine built on EventMachine and Ruby-SNMP"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
