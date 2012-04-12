require 'rubygems'
require 'snmp4em'

OID_SYSTEM = "1.3.6.1.2.1.1"
OID_SYSNAME = "1.3.6.1.2.1.1.5.0"
OID_SYSLOCATION = "1.3.6.1.2.1.1.6.0"

EM.run {
  snmp = SNMP4EM::Manager.new(:host => "192.168.1.1", :version => :SNMPv1)

  request = snmp.get([OID_SYSNAME, OID_SYSLOCATION])

  request.callback do |response|
    puts "System name = #{response[OID_SYSNAME]}"
    puts "System location = #{response[OID_SYSLOCATION]}"
  end

  request.errback do |error|
    puts "GET got error #{error}"
  end
}