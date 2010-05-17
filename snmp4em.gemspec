# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{snmp4em}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Norman Elton"]
  s.date = %q{2010-05-16}
  s.description = %q{A high-performance SNMP engine built on EventMachine and Ruby-SNMP}
  s.email = %q{normelton@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["lib/snmp4em.rb", "lib/snmp4em/common.rb", "lib/snmp4em/handler.rb", "lib/snmp4em/requests/snmp_get_request.rb", "lib/snmp4em/requests/snmp_getnext_request.rb", "lib/snmp4em/requests/snmp_set_request.rb", "lib/snmp4em/requests/snmp_walk_request.rb", "lib/snmp4em/snmp_request.rb", "lib/snmp4em/snmp_v1.rb", "snmp4em.gemspec", "Manifest"]
  s.homepage = %q{http://github.com/normelton/snmp4em}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Snmp4em", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{snmp4em}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A high-performance SNMP engine built on EventMachine and Ruby-SNMP}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
