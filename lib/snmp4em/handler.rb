module SNMP4EM
  class Handler < EventMachine::Connection  # @private
    def receive_data(data)
      begin
        message = SNMP::Message.decode(data)
      rescue Exception => err
        # the request that this malformed response corresponds to
        # will timeout and retry
        return
      end
      
      response = message.pdu

      #
      # in the event of a timeout retry, the request will have been 
      # pruned from the Manager, so the response is to an expired
      # request, ignore it.
      #

      if request = Manager.pending_requests[response.request_id]
        request.handle_response(response)
      end
    end
  end
end
