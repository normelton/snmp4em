require 'spec_helper'

describe SNMP4EM::Manager do

  before do
    SNMP4EM::Manager.class_eval do
      @pending_requests = {}
    end
  end

  describe "#track_request" do

    it "should assign a random and unique id to each request" do
      em do
        request = SNMP4EM::TestRequest.new
        other_request = SNMP4EM::TestRequest.new

        SNMP4EM::Manager.should_receive(:rand).and_return(1, 1, 2)
        SNMP4EM::Manager.track_request(request)
        SNMP4EM::Manager.track_request(other_request)

        request.snmp_id.should == 1
        other_request.snmp_id.should == 2
      end
    end

    it "should prune requests when their request id changes" do
      em do
        request = SNMP4EM::TestRequest.new

        SNMP4EM::Manager.should_receive(:rand).and_return(1, 2)
        SNMP4EM::Manager.track_request(request)
        request.snmp_id.should == 1
        SNMP4EM::Manager.pending_requests.size.should == 1

        SNMP4EM::Manager.track_request(request)
        request.snmp_id.should == 2
        SNMP4EM::Manager.pending_requests.size.should == 1
      end
    end

  end

  describe "#initialize" do

    it "should default to v2c" do
      em do
        SNMP4EM::Manager.new.version.should == :SNMPv2c
      end
    end

    it "should create the class' UDP socket" do
      em do
        SNMP4EM::Manager.new
        SNMP4EM::Manager.socket.should be_a EventMachine::Connection
      end
    end


    context "when using v2c" do

      it "should acquire the #getbulk method" do
        em do
          SNMP4EM::Manager.new.methods.should include :getbulk
        end
      end

    end

    context "when using v1" do

      it "should not acquire the #getbulk method" do
        em do
          SNMP4EM::Manager.new(:version => :SNMPv1).methods.should_not include :getbulk
        end
      end

    end

  end

end
