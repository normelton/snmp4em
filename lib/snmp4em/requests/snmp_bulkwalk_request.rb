module SNMP4EM

  # This implements EM::Deferrable, so you can hang a callback() or errback() to retrieve the results.

  class SnmpBulkWalkRequest < SnmpRequest
    attr_accessor :snmp_id

    # SNMP-BULKWALK is faked using GETBULK queries until the returned OID isn't a subtree of the walk OID.
    #
    # Note that this library supports walking multiple base OIDs in parallel, and that the walk fails
    # atomically with a list of OIDS that failed to gather.

    def on_init args
      @oids.each{|oid| oid.merge!({:next_oid => oid[:requested_oid], :responses => {}})}
    end

    def handle_response(response) #:nodoc:
      super

      if response.error_status == :noError
        vb_list = response.vb_list
        vb_index = 0
        curr_pending_oids = pending_oids

        while response_vb = vb_list.shift
          oid = curr_pending_oids[vb_index % curr_pending_oids.count]
          response_oid = response_vb.name

          next unless oid[:state] == :pending

          if response_vb.value == SNMP::EndOfMibView
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

      send
    end

    private
    
    def send
      Manager.track_request(self)

      vb_list = SNMP::VarBindList.new(pending_oids.collect{|oid| oid[:next_oid]})
      request = SNMP::GetBulkRequest.new(@snmp_id, vb_list)
      
      request.max_repetitions = 10
      request.non_repeaters = 0

      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      super(message)
    end
  end  
end
