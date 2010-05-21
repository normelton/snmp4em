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

        response.varbind_list.each_index do |i|
          walk_oid = @pending_oids[i]
          response_vb = response.varbind_list[i]

          if response_vb.name.to_s.start_with?(walk_oid.to_s)
            responses_by_walk_oid[walk_oid] = response_vb
            @next_oids[walk_oid] = response_vb.name
          else
            @next_oids.delete(walk_oid)
          end
        end

        responses_by_walk_oid.each do |walk_oid, response_vb|
          @responses[walk_oid.to_s] ||= {}
          value = @return_raw || !response_vb.value.respond_to?(:rubify) ? response_vb.value : response_vb.value.rubify
          index = response_vb.name.to_s.gsub("#{walk_oid.to_s}.", '').to_i
          @responses[walk_oid.to_s][index] = value
        end
      
        @max_results -= 1 unless @max_results.nil?
      else
        @errors ||= []
        error_oid = response.varbind_list[response.error_index].name
        @errors << SNMP::ResponseError.new("Couldn't gather: #{error_oid} -> #{response.error_status}")
        fail @errors if @error_retries < 1 
        @error_retries -= 1
      end

      if @next_oids.empty? || @max_results.to_i < 0
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        send
      end
    end

    private
    
    def send
      Manager.track_request(self)

      unless @next_oids
        @next_oids = {}
        @pending_oids.each do |walk_oid|
          @next_oids[walk_oid] = walk_oid
        end
      end
      

      vb_list = SNMP::VarBindList.new(@next_oids.values)
      request = SNMP::GetNextRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)
      
      super(message)
    end
  end  
end
