module SNMP4EM
  
  # This implements EM::Deferrable, so you can hang a callback() or errback() to retrieve the results.

  class SnmpGetBulkRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-GETBULK request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be fetched. As
    # responses come back from the agent, this array will be pruned of any error-producing OIDs. Once no errors
    # are returned, the @responses hash will be populated and returned.

    def initialize(sender, oids, args = {}) #:nodoc:
      @nonrepeaters = args[:nonrepeaters] || 0
      @maxrepetitions = args[:maxrepetitions] || 10
      
      super
    end
    
    def handle_response(response) #:nodoc:
      if response.error_status == :noError
        # No errors, populate the @responses object so it can be returned

        @nonrepeaters.times do |i|
          request_oid = @pending_oids.shift
          response_vb = response.vb_list[i]

          @responses[request_oid.to_s] = [[response_vb.name, response_vb.value]]
        end

        (@nonrepeaters ... response.vb_list.size).each do |i|
          request_oid = @pending_oids[(i - @nonrepeaters) % @pending_oids.size]
          response_vb = response.vb_list[i]
          
          @responses[request_oid.to_s] ||= Array.new
          @responses[request_oid.to_s] << [response_vb.name, response_vb.value]
        end
        
        @pending_oids.clear
        
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
        
        if (!@return_raw)
          @responses.each_pair do |search_oid, values|
            values.collect! do |oid_value|
              oid_value[1] = oid_value[1].rubify if oid_value[1].respond_to?(:rubify)
              oid_value
            end
          
            @responses[search_oid] = values
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

    def send
      Manager.track_request(self)

      # Send the contents of @pending_oids

      vb_list = SNMP::VarBindList.new(@pending_oids)
      request = SNMP::GetBulkRequest.new(@snmp_id, vb_list)
      
      request.max_repetitions = @maxrepetitions
      request.non_repeaters = @nonrepeaters
      
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      super(message)
    end
  end  
end
