require "spec_helpers.rb"

describe "When performing a single SNMPv2 GETNEXT request" do
  it "should fetch the correct value" do
    @snmp_v2.getnext("1.9.9.2.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.2.1"].size).to eq(2)
      expect(response["1.9.9.2.1"].first).to eq("1.9.9.2.2")
      expect(response["1.9.9.2.1"].last).to eq("BBB")
    end
  end

  it "should return SNMP:EndOfMibView if the requested OID is at the end of the MIB" do
    @snmp_v2.getnext("1.10.10.10").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.10.10.10"]).to be_a(SNMP::ResponseError)
      expect(response["1.10.10.10"].error_status).to eq(:endOfMibView)
    end
  end
end

describe "When performing multiple SNMPv2 GETNEXT requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.getnext(["1.9.9.2.1", "1.9.9.2.2"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.2.1"].size).to eq(2)
      expect(response["1.9.9.2.1"].first).to eq("1.9.9.2.2")
      expect(response["1.9.9.2.1"].last).to eq("BBB")

      expect(response["1.9.9.2.2"].size).to eq(2)
      expect(response["1.9.9.2.2"].first).to eq("1.9.9.2.3")
      expect(response["1.9.9.2.2"].last).to eq("CCC")
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v2.getnext(["1.9.9.2.1", "1.10.10.10"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.2.1"].size).to eq(2)
      expect(response["1.9.9.2.1"].first).to eq("1.9.9.2.2")
      expect(response["1.9.9.2.1"].last).to eq("BBB")

      expect(response["1.10.10.10"]).to be_a(SNMP::ResponseError)
      expect(response["1.10.10.10"].error_status).to eq(:endOfMibView)
    end
  end
end