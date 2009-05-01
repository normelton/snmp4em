require "snmp_request.rb"

module SNMP4EM

  # Returned from SNMP4EM::SNMPv1.walk(). This implements EM::Deferrable, so you can hang a callback()
  # or errback() to retrieve the results.

  class SnmpWalkRequest < SnmpRequest
    attr_reader :snmp_id

    # For an SNMP-WALK request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be walked.
    # Note that this library supports walking multiple OIDs in parallel. Once any error-producing OIDs are removed,
    # a series of SNMP-GETNEXT requests are sent. Each response OID is checked to see if it begins with the walk OID.
    # If so, the incoming OID/value pair is appended to the @response hash, and will be used in subsequent GETNEXT
    # requests. Once an OID is returned that does not begin with the walk OID, that walk OID is removed from the
    # @pending_oids array.

    def initialize(sender, oids, args = {}) #:nodoc:
      @sender = sender
      
      @timeout_timer = nil
      @timeout_retries = @sender.retries
      @error_retries = oids.size
      
      @return_raw    = args[:return_raw]    || false
      @max_results   = args[:max_results]   || nil
      
      @responses = Hash.new
      @pending_oids = SNMP::VarBindList.new(oids).collect{|r| r.name}

      init_callbacks
      send
    end
    
    def handle_response(response) #:nodoc:
      oids_to_delete = []

      if (response.error_status == :noError)
        response.varbind_list.each_index do |i|
          walk_oid = @pending_oids[i]
          response_vb = response.varbind_list[i]
          
          # Initialize the responses array if necessary
          @responses[walk_oid.to_s] ||= Array.new
          
          # If the incoming response-oid begins with the walk-oid, then append the pairing
          # to the @response array. Otherwise, add it to the list of oids ready to delete
          if (response_vb.name[0,walk_oid.length] == walk_oid)
            @responses[walk_oid.to_s] << [response_vb.name, response_vb.value]
          else
            # If we were to delete thid oid from @pending_oids now, it would mess up the
            # @pending_oids[i] call above.
            oids_to_delete << walk_oid
          end
        end
      
        @max_results -= 1 unless @max_results.nil?
      
      else
        error_oid = @pending_oids[response.error_index - 1]
        oids_to_delete << error_oid
        
        @responses[error_oid.to_s] = SNMP::ResponseError.new(response.error_status)
        @error_retries -= 1
      end
      
      oids_to_delete.each{|oid| @pending_oids.delete oid}
      
      if (@pending_oids.empty? || (@error_retries < 0) || (@max_results.to_i < 0))
        @responses.each_pair do |oid, value|
          @responses[oid] = value.rubify if (!@return_raw && value.respond_to?(:rubify))
        end
        
        # Send the @responses back to the requester, we're done!
        succeed @responses
      else
        send
      end
    end

    private
    
    def send
      @snmp_id = generate_snmp_id

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
      message = SNMP::Message.new(:SNMPv1, @sender.community_ro, request)
      
      super(message)
    end
  end  
end
