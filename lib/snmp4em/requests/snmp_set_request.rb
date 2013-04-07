module SNMP4EM

  # Returned from SNMP4EM::SNMPv1.set(). This implements EM::Deferrable, so you can hang a callback()
  # or errback() to retrieve the results.

  class SnmpSetRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-SET request, @pending_varbinds will by an SNMP::VarBindList, initially populated from the
    # provided oids hash. Variables can be passed as specific types from the SNMP library (i.e. SNMP::IpAddress)
    # or as ruby native objects, in which case they will be cast into the appropriate SNMP object. As responses
    # are returned, the @pending_varbinds object will be pruned of any error-producing varbinds. Once no errors
    # are produced, the @responses object is populated and returned.

    def initialize(sender, oids, args = {}) #:nodoc:
      @oids = [*oids].collect { |oid_str, value| { :requested_oid => SNMP::ObjectId.new(oid_str), :value => format_outgoing_value(value), :state => :pending, :response => nil }}
      super
    end
    
    def handle_response(response) #:nodoc:
      if (response.error_status == :noError)
        pending_oids.zip(response.varbind_list).each do |oid, response_vb|
          oid[:response] = true
          oid[:state] = :complete
        end
      
      else
        error_oid = pending_oids[response.error_index - 1]
        error_oid[:state] = :error
        error_oid[:error] = SNMP::ResponseError.new(response.error_status)
      end
      
      if pending_oids.empty?
        result = {}

        @oids.each do |oid|
          requested_oid = oid[:requested_oid]
          result[requested_oid] = oid[:error] || oid[:response]
        end

        succeed result
        return
      end
    
      send
    end

    private
    
    def send
      Manager.track_request(self)

      pending_varbinds = pending_oids.collect{|oid| SNMP::VarBind.new(oid[:requested_oid], oid[:value])}

      vb_list = SNMP::VarBindList.new(pending_varbinds)
      request = SNMP::SetRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_rw, request)
      
      super(message)
    end
  end  
end
