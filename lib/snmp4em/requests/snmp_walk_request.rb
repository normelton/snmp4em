module SNMP4EM

  # Returned from SNMP4EM::SNMPv1.walk(). This implements EM::Deferrable, so you can hang a callback()
  # or errback() to retrieve the results.

  class SnmpWalkRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-WALK request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be walked.
    # Note that this library supports walking multiple OIDs in parallel. Once any error-producing OIDs are removed,
    # a series of SNMP-GETNEXT requests are sent. Each response OID is checked to see if it begins with the walk OID.
    # If so, the incoming OID/value pair is appended to the @response hash, and will be used in subsequent GETNEXT
    # requests. Once an OID is returned that does not begin with the walk OID, that walk OID is removed from the
    # @pending_oids array.
    
    def handle_response(response) #:nodoc:
      if response.error_status == :noError
        responses_by_walk_oid = {}

        oid_indexes_to_delete = []

        response.varbind_list.each_index do |i|
          walk_oid = @pending_oids[i]
          response_vb = response.varbind_list[i]

          if response_vb.name.to_s.start_with?(walk_oid.to_s)
            responses_by_walk_oid[walk_oid] = response_vb
          else
            oid_indexes_to_delete << i
          end
        end

        oid_indexes_to_delete.each do |i|
          @pending_oids.delete_at(i)
        end
          
        responses_by_walk_oid.each do |walk_oid, response_vb|
          @responses[walk_oid.to_s] ||= []
          value = @return_raw || !response_vb.value.respond_to?(:rubify) ? response_vb.value : response_vb.value.rubify
          @responses[walk_oid.to_s] << [response_vb.name.to_s, value]
        end
      
        @max_results -= 1 unless @max_results.nil?
      else
        error_oid = @pending_oids.delete_at(responses.error_index - 1)
        @responses[error_oid.to_s] = SNMP::ResponseError.new(response.error_status)
        @error_retries -= 1
      end
      
      if @error_retries < 0 
        fail "exhausted all retries"
      elsif @pending_oids.empty? || @max_results.to_i < 0
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        send
      end
    end

    private
    
    def send
      Manager.manage_request(self)

      # This oids array will consist of all the oids that need to be getnext'd
      oids = Array.new
      
      @pending_oids.each do |oid|
        # If there's already a response for this walk-oid, then use the last returned oid, otherwise
        # start with the walk-oid.
        if @responses.has_key?(oid.to_s)
          oids << @responses[oid.to_s].last.first
        else
          oids << oid
        end
      end

      vb_list = SNMP::VarBindList.new(oids)
      request = SNMP::GetNextRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)
      
      super(message)
    end
  end  
end
