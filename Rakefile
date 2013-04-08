require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

desc "Run instances of snmpd for use during testing"
task :server do
  `snmpd -f -Le -C -c ./spec/snmpd/snmpd.conf 127.0.0.1:1620`
end