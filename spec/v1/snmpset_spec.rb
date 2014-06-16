require "spec_helpers.rb"

describe "When performing a single SNMPv1 SET request" do
  it "should set the value" do
    @snmp_v1.set({"1.9.9.3.1" => "New Value"}).expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.3.1"]).to be true
    end
  end

  it "should return a SNMP::ResponseError OID is not writable" do
    @snmp_v1.set({"1.9.9.3.3" => "New Value"}).expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.3.3"]).to be_a(SNMP::ResponseError)
      expect(response["1.9.9.3.3"].error_status).to eq(:noSuchName)
    end
  end
end

describe "When performing multiple SNMPv1 SET requests simultaneously" do
  it "should set two values correctly" do
    @snmp_v1.set({"1.9.9.3.1" => "New Value", "1.9.9.3.2" => "New Value"}).expect do |response|
      expect(response.size).to eq(2)
      expect(response["1.9.9.3.1"]).to be true
      expect(response["1.9.9.3.2"]).to be true
    end
  end

  it "should set one value correctly if the other is not writable" do
    @snmp_v1.set({"1.9.9.3.1" => "New Value", "1.9.9.3.3" => "New Value"}).expect do |response|
      expect(response.size).to eq(2)
      expect(response["1.9.9.3.1"]).to be true
      expect(response["1.9.9.3.3"]).to be_a(SNMP::ResponseError)
      expect(response["1.9.9.3.3"].error_status).to eq(:noSuchName)
    end
  end
end