# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{snmp4em}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Norman Elton"]
  s.date = %q{2009-05-04}
  s.description = %q{A high-performance SNMP engine built on EventMachine and Ruby-SNMP}
  s.email = %q{normelton@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["lib/common.rb", "lib/handler.rb", "lib/requests/snmp_get_request.rb", "lib/requests/snmp_getnext_request.rb", "lib/requests/snmp_set_request.rb", "lib/requests/snmp_walk_request.rb", "lib/snmp4em.rb", "lib/snmp_request.rb", "Rakefile", "README", "snmp4em.gemspec", "Manifest"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/normelton/snmp4em}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Snmp4em", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{snmp4em}
  s.rubygems_version = %q{1.3.2}
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
