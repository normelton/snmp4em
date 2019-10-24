module SNMP4EM
  
  # The result of calling {SNMPv2Requests#getbulk}.

  class SnmpGetBulkRequest < SnmpRequest
    attr_accessor :snmp_id

    # Used to register a callback that is triggered when the query result is ready. The resulting object is passed as a parameter to the block.
    def callback &block
      super
    end

    # Used to register a callback that is triggered when query fails to complete successfully.
    def errback &block
      super
    end

    def on_init args  # @private
      @oids.each_index do |i|
        @oids[i][:responses] = {}
        @oids[i][:method] = (i < (args[:non_repeaters] || 0) ? :non_repeating : :repeating)
      end

      @max_results ||= 10
    end
    
    def handle_response(response)  # @private
      super
      
      pending_repeating_oids = pending_oids.select{|oid| oid[:method] == :repeating}
      pending_non_repeating_oids = pending_oids.select{|oid| oid[:method] == :non_repeating}

      if response.error_status == :noError
        # No errors, populate the @responses object so it can be returned

        vb_list = response.vb_list
        vb_index = 0

        pending_non_repeating_oids.each do |oid|
          response_vb = vb_list.shift
          oid[:responses][response_vb.name.to_s] = format_value(response_vb)
          oid[:state] = :complete
        end

        while response_vb = vb_list.shift
          oid = pending_repeating_oids[vb_index % pending_repeating_oids.count]
          oid[:responses][response_vb.name.to_s] = format_value(response_vb) unless response_vb.value == SNMP::EndOfMibView
          oid[:state] = :complete
          vb_index += 1
        end
        
      else
        error_oid = pending_oids[response.error_index - 1]
        error_oid[:state] = :error
        error_oid[:error] = SNMP::ResponseError.new(response.error_status)
      end
      
      if pending_oids.empty?
        result = {}

        @oids.each do |oid|
          requested_oid = oid[:requested_string]
          result[requested_oid] = oid[:error] || oid[:responses]
        end

        succeed result
        return
      end

      send_self
    end

    private

    def send_self
      @sender.track_request(self)

      vb_list = SNMP::VarBindList.new(pending_oids.collect{|oid| oid[:requested_oid]})

      max_repetitions = @max_results
      non_repeaters = pending_oids.select{|oid| oid[:method] == :non_repeating}.count

      # Gracefully handle a new constructor introduced in SNMP 1.3.1
      if Gem::Version.new(SNMP::VERSION) >= Gem::Version.new("1.3.1")
        request = SNMP::GetBulkRequest.new(@snmp_id, vb_list, non_repeaters, max_repetitions)
      else
        request = SNMP::GetBulkRequest.new(@snmp_id, vb_list)
        
        request.max_repetitions = max_repetitions
        request.non_repeaters = non_repeaters
      end

      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      send_msg(message)
    end
  end  
end
