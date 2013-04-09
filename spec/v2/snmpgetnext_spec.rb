require "spec_helpers.rb"

describe "When performing a single SNMPv2 GETNEXT request" do
  it "should fetch the correct value" do
    @snmp_v2.getnext("1.9.9.2.1").expect do |response|
      response.should have(1).item
      response["1.9.9.2.1"].should == ["1.9.9.2.2", "BBB"]
    end
  end

  it "should return SNMP:EndOfMibView if the requested OID is at the end of the MIB" do
    @snmp_v2.getnext("1.10.10.10").expect do |response|
      response.should have(1).item
      response["1.10.10.10"].should == ["1.10.10.10", SNMP::EndOfMibView]
    end
  end
end

describe "When performing multiple SNMPv2 GETNEXT requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.getnext(["1.9.9.2.1", "1.9.9.2.2"]).expect do |response|
      response.should have(2).items
      response["1.9.9.2.1"].should == ["1.9.9.2.2", "BBB"]
      response["1.9.9.2.2"].should == ["1.9.9.2.3", "CCC"]
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v2.getnext(["1.9.9.2.1", "1.10.10.10"]).expect do |response|
      response.should have(2).items
      response["1.9.9.2.1"].should == ["1.9.9.2.2", "BBB"]
      response["1.10.10.10"].should == ["1.10.10.10", SNMP::EndOfMibView]
    end
  end
end