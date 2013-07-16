module SNMP4EM
  class SnmpRequest
    include EM::Deferrable

    attr_accessor :timeout_timer

    def initialize(sender, oids, args = {})
      @sender = sender
      
      @oids ||= [*oids].collect { |oid_str| { :requested_string => oid_str, :requested_oid => SNMP::ObjectId.new(oid_str), :state => :pending }}

      retries = args[:retries] || @sender.retries
      timeout = args[:timeout] || @sender.timeout

      if retries.is_a?(Array)
        @timeouts = retries.clone
      else
        @timeouts = (retries + 1).times.collect { timeout }
      end
      
      @return_raw = args[:return_raw] || false
      @max_results = args[:max_results] || nil
      
      init_callbacks
      on_init(args) if respond_to?(:on_init)
      send_msg
    end

    def pending_oids  # @private
      @oids.select{|oid| oid[:state] == :pending}
    end

    def format_value vb  # @private
      if [SNMP::EndOfMibView, SNMP::NoSuchObject, SNMP::NoSuchInstance].include? vb.value
        SNMP::ResponseError.new(vb.value)
      elsif @return_raw || !vb.value.respond_to?(:rubify)
        vb.value
      else
        vb.value.rubify
      end
    end

    def format_outgoing_value value  # @private
      if value.is_a? Integer
        return SNMP::Integer.new(value)
      elsif value.is_a? String
        return SNMP::OctetString.new(value)
      else
        return value
      end
    end
    
    def init_callbacks  # @private
      self.callback do
        Manager.pending_requests.delete(@snmp_id)
      end
      
      self.errback do
        @timeout_timer.cancel
        Manager.pending_requests.delete(@snmp_id)
      end
    end

    def send_msg(msg)  # @private
      @sender.send_msg msg

      @timeout_timer.cancel if @timeout_timer.is_a?(EM::Timer)

      @timeout_timer = EM::Timer.new(@timeouts.shift) do
        if @timeouts.empty?
          fail "exhausted all timeout retries"
        else
          send_msg
        end
      end
    end

    def handle_response response  # @private
      @timeout_timer.cancel
    end
  end
end
