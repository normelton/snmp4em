require "spec_helpers.rb"

describe "When performing a single SNMPv1 SET request" do
  it "should set the value" do
    @snmp.set({"1.9.9.3.1" => "New Value"}).expect do |response|
      response.should have(1).item
      response["1.9.9.3.1"].should == true
    end
  end

  it "should return a SNMP::ResponseError OID is not writable" do
    @snmp.set({"1.9.9.3.3" => "New Value"}).expect do |response|
      response.should have(1).item
      response["1.9.9.3.3"].should be_a(SNMP::ResponseError)
      response["1.9.9.3.3"].to_s.should == "notWritable"
    end
  end
end

describe "When performing multiple SNMPv1 SET requests simultaneously" do
  it "should set two values correctly" do
    @snmp.set({"1.9.9.3.1" => "New Value", "1.9.9.3.2" => "New Value"}).expect do |response|
      response.should have(2).items
      response["1.9.9.3.1"].should == true
      response["1.9.9.3.2"].should == true
    end
  end

  it "should set one value correctly if the other is not writable" do
    @snmp.set({"1.9.9.3.1" => "New Value", "1.9.9.3.3" => "New Value"}).expect do |response|
      response.should have(2).items
      response["1.9.9.3.1"].should == true
      response["1.9.9.3.3"].should be_a(SNMP::ResponseError)
      response["1.9.9.3.3"].to_s.should == "notWritable"
    end
  end
end