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

        response.varbind_list.each_index do |i|
          response_vb = response.varbind_list[i]
          response_oid = response_vb.name
          response_walk_oid = response_oid.dup; response_walk_oid.pop

          if @responses[response_walk_oid.to_s]
            value = @return_raw || !response_vb.value.respond_to?(:rubify) ? response_vb.value : response_vb.value.rubify
            @responses[response_walk_oid.to_s][response_oid.dup.pop] = value
            @next_oids[response_walk_oid] = response_oid
          else
            @next_oids.delete(@last_query[i])
          end
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

      #
      # @next_oids maps the walk oid to its next getnext oid
      #
      unless @next_oids
        @responses = {}
        @next_oids = {}
        @pending_oids.each do |walk_oid|
          @next_oids[walk_oid] = walk_oid
          @responses[walk_oid.to_s] = {}
        end
      end
      
      #
      # @last_query maps the index of the requested oid to the walk oid
      #
      i = 0
      @last_query = {}
      query_oids = \
        @next_oids.collect do |walk_oid, next_oid|
          @last_query[i] = walk_oid
          i += 1
          next_oid
        end

      vb_list = SNMP::VarBindList.new(query_oids)
      request = SNMP::GetNextRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)
      
      super(message)
    end
  end  
end
