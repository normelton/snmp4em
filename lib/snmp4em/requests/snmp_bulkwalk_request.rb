module SNMP4EM

  # The result of calling {SNMPv2cRequests#bulkwalk}.

  class SnmpBulkWalkRequest < SnmpRequest
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
      @oids.each{|oid| oid.merge!({:next_oid => oid[:requested_oid], :responses => {}})}
    end

    def handle_response(response)  # @private
      super

      if response.error_status == :noError
        vb_list = response.vb_list
        vb_index = 0
        curr_pending_oids = pending_oids

        while response_vb = vb_list.shift
          oid = curr_pending_oids[vb_index % curr_pending_oids.count]
          response_oid = response_vb.name

          next unless oid[:state] == :pending

          if SNMP::EndOfMibView == response_vb.value
            oid[:state] = :complete

          elsif ! response_oid.subtree_of?(oid[:requested_oid])
            oid[:state] = :complete
          else
            oid[:responses][response_oid.to_s] = format_value(response_vb)
            oid[:next_oid] = response_oid
          end

          vb_index += 1
        end

      else
        error_oid = pending_oids[response.error_index - 1]
        error_oid[:state] = :error
        error_oid[:error] = SNMP::ResponseError.new(response.error_status)
      end

      if pending_oids.empty? || (@max_results && @oids.collect{|oid| oid[:responses].count}.max >= @max_results)
        result = {}

        @oids.each do |oid|
          requested_oid = oid[:requested_string]
          result[requested_oid] = oid[:error] || oid[:responses]
        end

        succeed result
        return
      end

      send_msg
    end

    private
    
    def send_self
      @sender.track_request(self)

      vb_list = SNMP::VarBindList.new(pending_oids.collect{|oid| oid[:next_oid]})

      # Gracefully handle a new constructor introduced in SNMP 1.3.1
      if Gem::Version.new(SNMP::VERSION) >= Gem::Version.new("1.3.1")
        request = SNMP::GetBulkRequest.new(@snmp_id, vb_list, 0, 10)
      else
        request = SNMP::GetBulkRequest.new(@snmp_id, vb_list)
        
        request.max_repetitions = 10
        request.non_repeaters = 0
      end

      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      send_msg(message)
    end
  end  
end
