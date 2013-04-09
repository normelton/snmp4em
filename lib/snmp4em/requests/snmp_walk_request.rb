module SNMP4EM

  # The result of calling {SNMPCommonRequests#walk}.

  class SnmpWalkRequest < SnmpRequest
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
        pending_oids.zip(response.varbind_list).each do |oid, response_vb|
          response_oid = response_vb.name

          if response_vb.value == SNMP::EndOfMibView
            # For SNMPv2, this indicates we've reached the end of the MIB
            oid[:state] = :complete
          elsif ! response_oid.subtree_of?(oid[:requested_oid])
            oid[:state] = :complete
          else
            oid[:responses][response_oid.to_s] = format_value(response_vb)
            oid[:next_oid] = response_oid
          end
        end

      elsif response.error_status == :noSuchName
        # For SNMPv1, this indicates we've reached the end of the MIB
        error_oid = pending_oids[response.error_index - 1]
        error_oid[:state] = :complete

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
      request = SNMP::GetNextRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      super(message)
    end
  end  
end
