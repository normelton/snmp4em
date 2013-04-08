module SNMP4EM
  
  # This implements EM::Deferrable, so you can hang a callback() or errback() to retrieve the results.

  class SnmpGetBulkRequest < SnmpRequest
    attr_accessor :snmp_id

    # For an SNMP-GETBULK request, @pending_oids will be a ruby array of SNMP::ObjectNames that need to be fetched. As
    # responses come back from the agent, this array will be pruned of any error-producing OIDs. Once no errors
    # are returned, the @responses hash will be populated and returned.

    def on_init args
      @oids.each_index do |i|
        @oids[i][:responses] = {}
        @oids[i][:method] = (i < (args[:non_repeaters] || 0) ? :non_repeating : :repeating)
      end

      @max_results ||= 10
    end
    
    def handle_response(response) #:nodoc:
      super
      
      pending_repeating_oids = pending_oids.select{|oid| oid[:method] == :repeating}
      pending_non_repeating_oids = pending_oids.select{|oid| oid[:method] == :non_repeating}

      if response.error_status == :noError
        # No errors, populate the @responses object so it can be returned

        vb_list = response.vb_list
        vb_index = 0

        pending_non_repeating_oids.each do |oid|
          response_vb = vb_list.shift
          oid[:responses][response_vb.name] = format_value(response_vb)
          oid[:state] = :complete
        end

        while response_vb = vb_list.shift
          oid = pending_repeating_oids[vb_index % pending_repeating_oids.count]
          oid[:responses][response_vb.name] = format_value(response_vb)
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

      send
    end

    private

    def send
      Manager.track_request(self)

      vb_list = SNMP::VarBindList.new(pending_oids.collect{|oid| oid[:requested_oid]})
      request = SNMP::GetBulkRequest.new(@snmp_id, vb_list)
      
      request.max_repetitions = @max_results
      request.non_repeaters = pending_oids.select{|oid| oid[:method] == :non_repeating}.count
      
      message = SNMP::Message.new(@sender.version, @sender.community_ro, request)

      PP.pp request

      super(message)
    end
  end  
end
