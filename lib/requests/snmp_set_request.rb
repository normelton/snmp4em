require "snmp_request.rb"

module SNMP4EM

  # Returned from SNMP4EM::SNMPv1.set(). This implements EM::Deferrable, so you can hang a callback()
  # or errback() to retrieve the results.

  class SnmpSetRequest < SnmpRequest
    attr_reader :snmp_id

    # For an SNMP-SET request, @pending_varbinds will by an SNMP::VarBindList, initially populated from the
    # provided oids hash. Variables can be passed as specific types from the SNMP library (i.e. SNMP::IpAddress)
    # or as ruby native objects, in which case they will be cast into the appropriate SNMP object. As responses
    # are returned, the @pending_varbinds object will be pruned of any error-producing varbinds. Once no errors
    # are produced, the @responses object is populated and returned.

    def initialize(sender, oids, args = {}) #:nodoc:
      @sender = sender
      
      @timeout_timer = nil
      @timeout_retries = @sender.retries
      @error_retries = oids.size
      
      @return_raw = args[:return_raw] || false
      
      @responses = Hash.new
      @pending_varbinds = SNMP::VarBindList.new()
      
      oids.each_pair do |oid,value|
        if value.is_a? Integer
          snmp_value = SNMP::Integer.new(value)
        elsif value.is_a? String
          snmp_value = SNMP::OctetString.new(value)
        end
        
        @pending_varbinds << SNMP::VarBind.new(oid,snmp_value)
      end

      init_callbacks
      send
    end
    
    def handle_response(response) #:nodoc:
      if (response.error_status == :noError)
        # No errors, set any remaining varbinds to true
        response.each_varbind do |vb|
          response_vb = @pending_varbinds.shift
          @responses[response_vb.name.to_s] = true
        end
      
      else
        # Got an error, remove that varbind from @pending_varbinds so we can try again
        error_vb = @pending_varbinds.delete_at(response.error_index - 1)
        @responses[error_vb.name.to_s] = SNMP::ResponseError.new(response.error_status)
      end
      
      if (@pending_varbinds.empty? || @error_retries.zero?)
        until @pending_varbinds.empty?
          error_vb = @pending_varbinds.shift
          @responses[error_vb.name.to_s] = SNMP::ResponseError.new(:genErr)
        end

        unless @return_raw
          @responses.each_pair do |oid, value|
            @responses[oid] = value.rubify if value.respond_to?(:rubify)
          end
        end
        
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        @error_retries -= 1
        
        debug "error-retry" do
          send
        end
      end
    end

    private
    
    def send
      # Send the contents of @pending_varbinds
      
      @snmp_id = generate_snmp_id

      debug "Sending set request for #{@pending_varbinds.collect{|vb| vb.name.to_s + '=' + vb.value.to_s}.join(', ')}"
      vb_list = SNMP::VarBindList.new(@pending_varbinds)
      request = SNMP::SetRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(:SNMPv1, @sender.community_rw, request)
      
      super(message)
    end
  end  
end
