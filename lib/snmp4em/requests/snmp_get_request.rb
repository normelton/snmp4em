module SNMP4EM
  
  # The result of calling {SNMPCommonRequests#get}.

  class SnmpGetRequest < SnmpRequest
    attr_accessor :snmp_id

    # Used to register a callback that is triggered when the query result is ready. The resulting object is passed as a parameter to the block.
    def callback &block
      super
    end

    # Used to register a callback that is triggered when query fails to complete successfully.
    def errback &block
      super
    end

    def handle_response(response)  # @private
      super
      
      if response.error_status == :noError
        pending_oids.zip(response.varbind_list).each do |oid, response_vb|
          oid[:response] = format_value(response_vb)
          oid[:state] = :complete
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
          result[requested_oid] = oid[:error] || oid[:response]
        end

        succeed result
        return
      end
    
      send_msg
    end

    private

    def send_msg
      Manager.track_request(self)

      query_oids = @oids.select{|oid| oid[:state] == :pending}.collect{|oid| oid[:requested_oid]}

      vb_list = SNMP::VarBindList.new(query_oids)
      request = SNMP::GetRequest.new(@snmp_id, vb_list)
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      super(message)
    end
  end  
end
