require "spec_helpers.rb"

describe "When performing a single SNMPv1 GET request" do
  it "should fetch the correct value" do
    @snmp_v1.get("1.9.9.1.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.1.1"]).to eq("AAA")
    end
  end

  it "should return SNMP::NoSuchObject if the value does not exist" do
    @snmp_v1.get("1.9.9.1.5").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.1.5"]).to be_a(SNMP::ResponseError)
      expect(response["1.9.9.1.5"].error_status).to eq(:noSuchName)
    end
  end
end

describe "When performing multiple SNMPv1 GET requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v1.get(["1.9.9.1.1", "1.9.9.1.2"]).expect do |response|
      expect(response.size).to eq(2)
      expect(response["1.9.9.1.1"]).to eq("AAA")
      expect(response["1.9.9.1.2"]).to eq("BBB")
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v1.get(["1.9.9.1.1", "1.9.9.1.5"]).expect do |response|
      expect(response.size).to eq(2)
      expect(response["1.9.9.1.1"]).to eq("AAA")
      expect(response["1.9.9.1.5"]).to be_a(SNMP::ResponseError)
      expect(response["1.9.9.1.5"].error_status).to eq(:noSuchName)
    end
  end
end