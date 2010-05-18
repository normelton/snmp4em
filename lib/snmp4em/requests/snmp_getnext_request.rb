module SNMP4EM

  # Returned from SNMP4EM::SNMPv1.getnext(). This implements EM::Deferrable, so you can hang a callback()
  # or errback() to retrieve the results.

  class SnmpGetNextRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-GETNEXT request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be fetched. As
    # responses come back from the agent, this array will be pruned of any error-producing OIDs. Once no errors
    # are returned, the @responses hash will be populated and returned. The values of the hash will consist of a
    # two-element array, in the form of [OID, VALUE], showing the next oid & value.

    def initialize(sender, oids, args = {}) #:nodoc:
      @sender = sender
      
      @timeout_timer = nil
      @timeout_retries = @sender.retries
      @error_retries = oids.size
      
      @return_raw = args[:return_raw] || false
      
      @responses = Hash.new
      @pending_oids = SNMP::VarBindList.new(oids).collect{|r| r.name}

      init_callbacks
      send
    end
    
    def handle_response(response) #:nodoc:
      if (response.error_status == :noError)
        # No errors, populate the @responses object so it can be returned
        response.each_varbind do |vb|
          request_oid = @pending_oids.shift
          @responses[request_oid.to_s] = [vb.name, vb.value]
        end
      
      else
        # Got an error, remove that oid from @pending_oids so we can try again
        error_oid = @pending_oids.delete_at(response.error_index - 1)
        @responses[error_oid.to_s] = SNMP::ResponseError.new(response.error_status)
      end
      
      if (@pending_oids.empty? || @error_retries.zero?)
        until @pending_oids.empty?
          error_oid = @pending_oids.shift
          @responses[error_oid.to_s] = SNMP::ResponseError.new(:genErr)
        end

        @responses.each_pair do |oid, value|
          if value.is_a? Array
            @responses[oid][1] = value[1].rubify if (!@return_raw && value[1].respond_to?(:rubify))
          else
            @responses[oid] = value.rubify if (!@return_raw && value.respond_to?(:rubify))
          end
        end
        
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        @error_retries -= 1
        send
      end
    end

    private
    
    def send #:nodoc:
      Manager.manage_request(self)

      # Send the contents of @pending_oids

      vb_list = SNMP::VarBindList.new(@pending_oids)
      request = SNMP::GetNextRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)
      
      super(message)
    end
  end  
end
