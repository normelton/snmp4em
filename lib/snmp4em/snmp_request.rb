module SNMP4EM
  class SnmpRequest #:nodoc:
    include EM::Deferrable
    
    def generate_snmp_id
      begin
        snmp_id = rand(1073741823)  # Largest Fixnum
      end until (SNMPv1.pending_requests.select{|r| r.snmp_id == snmp_id}.empty?)        

      return snmp_id
    end

    def init_callbacks
      self.callback do
        SNMPv1.pending_requests.delete_if {|r| r.snmp_id == @snmp_id}
        @timeout_timer.cancel
      end
      
      self.errback do
        SNMPv1.pending_requests.delete_if {|r| r.snmp_id == @snmp_id}
        @timeout_timer.cancel
      end
    end

    def send(msg)
      @sender.send msg

      @timeout_timer.cancel if @timeout_timer.is_a?(EM::Timer)

      @timeout_timer = EM::Timer.new(@sender.timeout) do
        if (@timeout_retries > 0)
          send
          @timeout_retries -= 1
        else
          fail("timeout")
        end
      end
    end
  end
end