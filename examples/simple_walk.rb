require 'rubygems'
require 'snmp4em'

OID_SYSTEM = "1.3.6.1.2.1.1"
OID_SYSNAME = "1.3.6.1.2.1.1.5.0"
OID_SYSLOCATION = "1.3.6.1.2.1.1.6.0"


EM.run {
  snmp = SNMP4EM::Manager.new(:host => "192.168.1.1")

  request = snmp.walk(OID_SYSTEM)

  request.callback do |response|
    if (response[OID_SYSTEM].is_a? Array)
      response[OID_SYSTEM].each do |vb|
        puts "#{vb[0]} = #{vb[1]}"
      end
    else
      puts "Got error: #{response[OID_SYSTEM]}"
    end
  end

  request.errback do |error|
    puts "WALK got error #{error}"
  end
}