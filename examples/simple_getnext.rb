require 'rubygems'
require 'snmp4em'

OID_SYSTEM = "1.3.6.1.2.1.1"
OID_SYSNAME = "1.3.6.1.2.1.1.5.0"
OID_SYSLOCATION = "1.3.6.1.2.1.1.6.0"

EM.run {
  snmp = SNMP4EM::Manager.new(:host => "192.168.1.1")

  request = snmp.getnext(OID_SYSNAME)

  request.callback do |response|
    r = response[OID_SYSNAME]
    puts "The next OID is #{r[0]}, the next value is #{r[1]}"
  end

  request.errback do |error|
    puts "GETNEXT got error #{error}"
  end
}