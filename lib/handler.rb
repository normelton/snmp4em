module SNMP4EM
  module Handler #:nodoc:
    def receive_data(data)
      begin
        message = SNMP::Message.decode(data)
      rescue Exception => err
        return
      end
      
      response = message.pdu
      request_id = response.request_id
      
      if (request = SNMPv1.pending_requests.select{|r| r.snmp_id == request_id}.first)
        request.handle_response(response)
      end
    end
  end
end