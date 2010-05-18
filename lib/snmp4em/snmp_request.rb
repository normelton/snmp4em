module SNMP4EM
  class SnmpRequest #:nodoc:
    include EM::Deferrable

    def init_callbacks
      self.callback do
        SnmpConnection.pending_requests.delete(@snmp_id)
        @timeout_timer.cancel
      end
      
      self.errback do
        SnmpConnection.pending_requests.delete(@snmp_id)
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
