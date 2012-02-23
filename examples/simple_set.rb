require 'rubygems'
require 'snmp4em'

OID_SYSTEM = "1.3.6.1.2.1.1"
OID_SYSNAME = "1.3.6.1.2.1.1.5.0"
OID_SYSLOCATION = "1.3.6.1.2.1.1.6.0"

EM.run {
  snmp = SNMP4EM::Manager.new(:host => "192.168.1.1")

  request = snmp.set({OID_SYSNAME => "My System Name", OID_SYSLOCATION => "My System Location"})

  request.callback do |response|
    if (response[OID_SYSNAME] == true)
      puts "System name set successful"
    else
      puts "System name set unsuccessful: #{response[OID_SYSNAME]}"
    end

    if (response[OID_SYSLOCATION] == true)
      puts "System location set successful"
    else
      puts "System location set unsuccessful: #{response[OID_SYSLOCATION]}"
    end
  end

  request.errback do |error|
    puts "SET got error #{error}"
  end
}