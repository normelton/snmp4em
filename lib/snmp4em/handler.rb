module SNMP4EM
  module Handler #:nodoc:
    def receive_data(data)
      begin
        message = SNMP::Message.decode(data)
      rescue Exception => err
        return
      end
      
      response = message.pdu
      request = Manager.pending_requests[response.request_id]

      request.handle_response(response) if request
    end
  end
end
