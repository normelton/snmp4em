module SNMP4EM

  # This implements EM::Deferrable, so you can hang a callback() or errback() to retrieve the results.

  class SnmpWalkRequest < SnmpRequest
    attr_accessor :snmp_id

    # SNMP-WALK is faked using GETNEXT queries until the returned OID isn't a subtree of the walk OID.
    #
    # @next_oids is a hash that maps the base walk OID to the next OID to be queried.
    #
    # @query_indexes simply tracks the order in which the next_oids were packaged up, in order to
    # determine which query left the subtree
    #
    # Note that this library supports walking multiple base OIDs in parallel, and that the walk fails
    # atomically with a list of OIDS that failed to gather.
    #
    def handle_response(response) #:nodoc:
      if response.error_status == :noError

        response.varbind_list.each_index do |i|
          response_vb = response.varbind_list[i]
          response_oid = response_vb.name
          response_walk_oid = response_oid.dup; response_walk_oid.pop

          if response_walk_oid.subtree_of?(@query_indexes[i])
            value = @return_raw || !response_vb.value.respond_to?(:rubify) ? response_vb.value : response_vb.value.rubify
            @responses[response_walk_oid.to_s][response_oid.dup.pop] = value
            @next_oids[response_walk_oid] = response_oid
          else
            @next_oids.delete(@query_indexes[i])
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
      # @query_indexes maps the index of the requested oid to the walk oid
      #
      i = 0
      @query_indexes = {}
      query_oids = \
        @next_oids.collect do |walk_oid, next_oid|
          @query_indexes[i] = walk_oid
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
