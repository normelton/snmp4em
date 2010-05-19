module SNMP4EM
  class Handler < EventMachine::Connection #:nodoc:
    def receive_data(data)
      begin
        message = SNMP::Message.decode(data)
      rescue Exception => err
        # the request that this malformed response corresponds to
        # will timeout and retry
        return
      end
      
      response = message.pdu
      request = Manager.pending_requests[response.request_id]

      #
      # in the event of a timeout retry, the request will have been 
      # pruned from the Manager, so the response is to an expired
      # request, ignore it.
      #
      request.handle_response(response) if request
    end
  end
end
