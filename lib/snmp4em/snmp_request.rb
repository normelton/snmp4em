module SNMP4EM
  class SnmpRequest #:nodoc:
    include EM::Deferrable

    def initialize(sender, oids, args = {}) #:nodoc:
      _oids = [*oids]

      @sender = sender
      
      @timeout_timer = nil
      @timeout_retries = @sender.retries
      @error_retries = _oids.size
      
      @return_raw = args[:return_raw] || false
      
      @responses = {}
      @pending_oids = _oids.collect { |oid_str| SNMP::ObjectId.new(oid_str) }

      init_callbacks
      send
    end
    
    def init_callbacks
      self.callback do
        Manager.pending_requests.delete(@snmp_id)
        @timeout_timer.cancel
      end
      
      self.errback do
        Manager.pending_requests.delete(@snmp_id)
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
          fail "exhausted all timeout retries"
        end
      end
    end
  end
end
