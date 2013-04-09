require "spec_helpers.rb"

describe "When performing a single SNMPv2 GET request" do
  it "should fetch the correct value" do
    @snmp_v2.get("1.9.9.1.1").expect do |response|
      response.should have(1).item
      response["1.9.9.1.1"].should == "AAA"
    end
  end

  it "should return SNMP::NoSuchObject if the value does not exist" do
    @snmp_v2.get("1.9.9.1.5").expect do |response|
      response.should have(1).item
      response["1.9.9.1.5"].should == SNMP::NoSuchObject
    end
  end
end

describe "When performing multiple SNMPv2 GET requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.get(["1.9.9.1.1", "1.9.9.1.2"]).expect do |response|
      response.should have(2).items
      response["1.9.9.1.1"].should == "AAA"
      response["1.9.9.1.2"].should == "BBB"
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v2.get(["1.9.9.1.1", "1.9.9.1.5"]).expect do |response|
      response.should have(2).items
      response["1.9.9.1.1"].should == "AAA"
      response["1.9.9.1.5"].should == SNMP::NoSuchObject
    end
  end
end