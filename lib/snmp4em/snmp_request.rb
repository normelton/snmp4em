module SNMP4EM
  class SnmpRequest #:nodoc:
    include EM::Deferrable

    attr_accessor :timeout_timer

    def initialize(sender, oids, args = {}) #:nodoc:
      @sender = sender
      
      @oids ||= [*oids].collect { |oid_str| { :requested_string => oid_str, :requested_oid => SNMP::ObjectId.new(oid_str), :state => :pending }}

      @timeout_timer = nil
      @timeout_retries = args[:retries] || @sender.retries
      
      @return_raw = args[:return_raw] || false
      @max_results = args[:max_results] || nil
      
      init_callbacks
      on_init(args) if respond_to?(:on_init)
      send
    end

    def pending_oids
      @oids.select{|oid| oid[:state] == :pending}
    end

    def format_value vb
      if [SNMP::EndOfMibView, SNMP::NoSuchObject, SNMP::NoSuchInstance].include? vb.value
        SNMP::ResponseError.new(vb.value)
      elsif @return_raw || !vb.value.respond_to?(:rubify)
        vb.value
      else
        vb.value.rubify
      end
    end

    def format_outgoing_value value
      if value.is_a? Integer
        return SNMP::Integer.new(value)
      elsif value.is_a? String
        return SNMP::OctetString.new(value)
      else
        return value
      end
    end
    
    def init_callbacks
      self.callback do
        Manager.pending_requests.delete(@snmp_id)
      end
      
      self.errback do
        @timeout_timer.cancel
        Manager.pending_requests.delete(@snmp_id)
      end
    end

    def send(msg)
      @sender.send msg

      @timeout_timer.cancel if @timeout_timer.is_a?(EM::Timer)

      @timeout_timer = EM::Timer.new(@sender.timeout) do
        if @timeout_retries > 0
          send
          @timeout_retries -= 1
        else
          fail "exhausted all timeout retries"
        end
      end
    end

    def handle_response response
      @timeout_timer.cancel
    end
  end
end
