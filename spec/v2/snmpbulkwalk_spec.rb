require "spec_helpers.rb"

describe "When performing a single SNMPv2 BULKWALK request" do
  it "should fetch the correct values" do
    @snmp_v2.bulkwalk("1.9.9.5.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.5.1"].size).to eq(24)
    end
  end

  it "should fetch the correct value when walking an OID keyed by multiple values" do
    @snmp_v2.bulkwalk("1.9.9.5").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.5"].size).to eq(54)
    end
  end

  it "should return an empty hash if the requested OID is past the end of the MIB" do
    @snmp_v2.bulkwalk("1.10").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.10"]).to eq({})
    end
  end

  it "should return an empty hash if the requested OID does not have any children" do
    @snmp_v2.bulkwalk("1.9.9.5.1.2.5").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.5.1.2.5"]).to eq({})
    end
  end

  it "should return an empty hash if the requested OID does exist, but does not have any children" do
    @snmp_v2.bulkwalk("1.9.9.5.1.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.5.1.1"]).to eq({})
    end
  end
end

describe "When walking over a list of integer values" do
  it "should fetch the correct values" do
    @snmp_v2.bulkwalk("1.9.9.5.4").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.5.4"].size).to eq(2)
    end
  end
end

describe "When performing multiple SNMPv2 BULKWALK requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.bulkwalk(["1.9.9.5.1", "1.9.9.5.2"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.5.1"].size).to eq(24)
      expect(response["1.9.9.5.1"].all?{|k,v| k.start_with? "1.9.9.5.1"}).to be true
      expect(response["1.9.9.5.1"].all?{|k,v| v.start_with? "1-"}).to be true

      expect(response["1.9.9.5.2"].size).to eq(24)
      expect(response["1.9.9.5.2"].all?{|k,v| k.start_with? "1.9.9.5.2"}).to be true
      expect(response["1.9.9.5.2"].all?{|k,v| v.start_with? "2-"}).to be true
    end
  end

  it "should fetch two values correctly if one ends before the other" do
    @snmp_v2.bulkwalk(["1.9.9.5.1", "1.9.9.5.3"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.5.1"].size).to eq(24)
      expect(response["1.9.9.5.3"].size).to eq(4)
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v2.bulkwalk(["1.9.9.5.1", "1.9.9.5.6"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.5.1"].size).to eq(24)
      expect(response["1.9.9.5.6"]).to eq({})
    end
  end
end
