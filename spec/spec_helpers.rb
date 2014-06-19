require "snmp4em"

class SNMP4EM::SnmpRequest
  def expect &block
    self.callback &block
    self.errback {|error| fail error}

    self.callback { EM.stop }
    self.errback  { EM.stop }
  end
end

RSpec.configure do |config|
  config.around :each do |spec|
    EM.run do
      EM.error_handler do |error|
        fail error
      end

      EventMachine::Timer.new(3) do
        fail "Timeout"
      end

      @snmp_v1 = SNMP4EM::Manager.new(:port => 1620, :community_ro => "public", :community_rw => "private", :version => :SNMPv1)
      @snmp_v2 = SNMP4EM::Manager.new(:port => 1620, :community_ro => "public", :community_rw => "private", :version => :SNMPv2c)

      @snmp_v1_fiber = SNMP4EM::Manager.new(:port => 1620, :community_ro => "public", :community_rw => "private", :version => :SNMPv1, :fiber => true)

      spec.run
    end
  end
end
