require 'spec_helper'

describe SNMP4EM::Handler do

  before do
    SNMP4EM::Manager.class_eval do
      @pending_requests = {}
    end
  end

  describe "#receive_data" do

    it "should match responses to requests" do
      em do
        response = SNMP4EM::TestResponse.new
        response.request_id = 1

        message = SNMP4EM::TestMessage.new
        message.pdu = response
        SNMP::Message.should_receive(:decode).and_return(message)

        request = SNMP4EM::TestRequest.new
        SNMP4EM::Manager.should_receive(:rand).and_return(1)
        SNMP4EM::Manager.track_request(request)

        request.should_receive(:handle_response).with(response)
        SNMP4EM::Handler.new(nil).receive_data(nil)
      end

    end

  end

end
