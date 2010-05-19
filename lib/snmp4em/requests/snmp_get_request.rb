module SNMP4EM
  
  # This implements EM::Deferrable, so you can hang a callback() or errback() to retrieve the results.

  class SnmpGetRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-GET request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be fetched. As
    # responses come back from the agent, this array will be pruned of any error-producing OIDs. Once no errors
    # are returned, the @responses hash will be populated and returned.

    def handle_response(response) #:nodoc:
      if response.error_status == :noError
        # No errors, populate the @responses object so it can be returned
        response.each_varbind do |vb|
          request_oid = @pending_oids.shift
          value = @return_raw || !vb.value.respond_to?(:rubify) ? vb.value : vb.value.rubify

          @responses[request_oid.to_s] = value
        end
      
      else
        # Got an error, remove that oid from @pending_oids so we can try again
        error_oid = @pending_oids.delete_at(response.error_index - 1)
        @responses[error_oid.to_s] = SNMP::ResponseError.new(response.error_status)
      end

      if @error_retries < 0
        fail "exhausted all retries"
      elsif @pending_oids.empty?
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        @error_retries -= 1
        send
      end
    end

    private

    def send
      Manager.manage_request(self)

      # Send the contents of @pending_oids

      vb_list = SNMP::VarBindList.new(@pending_oids)
      request = SNMP::GetRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      super(message)
    end
  end  
end
