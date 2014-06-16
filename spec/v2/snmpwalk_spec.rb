require "spec_helpers.rb"

describe "When performing a single SNMPv2 WALK request" do
  it "should fetch the correct values" do
    @snmp_v2.walk("1.9.9.4.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.4.1"]).to eq({
        "1.9.9.4.1.1" => "1-A",
        "1.9.9.4.1.2" => "1-B",
        "1.9.9.4.1.3" => "1-C",
        "1.9.9.4.1.4" => "1-D"
      })
    end
  end

  it "should fetch the correct value when walking an OID keyed by multiple values" do
    @snmp_v2.walk("1.9.9.4").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.4"]).to eq({
        "1.9.9.4.1.1" => "1-A",
        "1.9.9.4.1.2" => "1-B",
        "1.9.9.4.1.3" => "1-C",
        "1.9.9.4.1.4" => "1-D",
        "1.9.9.4.2.1" => "2-A",
        "1.9.9.4.2.2" => "2-B",
        "1.9.9.4.2.3" => "2-C",
        "1.9.9.4.2.4" => "2-D",
        "1.9.9.4.3.1" => "3-A",
        "1.9.9.4.3.2" => "3-B"
      })
    end
  end

  it "should return an empty hash if the requested OID is past the end of the MIB" do
    @snmp_v2.walk("1.10").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.10"]).to eq({})
    end
  end

  it "should return an empty hash if the requested OID does not have any children" do
    @snmp_v2.walk("1.9.9.4.1.2.5").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.4.1.2.5"]).to eq({})
    end
  end

  it "should return an empty hash if the requested OID does exist, but does not have any children" do
    @snmp_v2.walk("1.9.9.4.1.1").expect do |response|
      expect(response.size).to eq(1)
      expect(response["1.9.9.4.1.1"]).to eq({})
    end
  end
end

describe "When performing multiple SNMPv2 WALK requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.walk(["1.9.9.4.1", "1.9.9.4.2"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.4.1"]).to eq({
        "1.9.9.4.1.1" => "1-A",
        "1.9.9.4.1.2" => "1-B",
        "1.9.9.4.1.3" => "1-C",
        "1.9.9.4.1.4" => "1-D"
      })

      expect(response["1.9.9.4.2"]).to eq({
        "1.9.9.4.2.1" => "2-A",
        "1.9.9.4.2.2" => "2-B",
        "1.9.9.4.2.3" => "2-C",
        "1.9.9.4.2.4" => "2-D"
      })
    end
  end

  it "should fetch two values correctly if one ends before the other" do
    @snmp_v2.walk(["1.9.9.4.1", "1.9.9.4.3"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.4.1"]).to eq({
        "1.9.9.4.1.1" => "1-A",
        "1.9.9.4.1.2" => "1-B",
        "1.9.9.4.1.3" => "1-C",
        "1.9.9.4.1.4" => "1-D"
      })

      expect(response["1.9.9.4.3"]).to eq({
        "1.9.9.4.3.1" => "3-A",
        "1.9.9.4.3.2" => "3-B",
      })
    end
  end

  it "should fetch one value correctly if the other does not exist" do
    @snmp_v2.walk(["1.9.9.4.1", "1.9.9.4.4"]).expect do |response|
      expect(response.size).to eq(2)

      expect(response["1.9.9.4.1"]).to eq({
        "1.9.9.4.1.1" => "1-A",
        "1.9.9.4.1.2" => "1-B",
        "1.9.9.4.1.3" => "1-C",
        "1.9.9.4.1.4" => "1-D"
      })

      expect(response["1.9.9.4.4"]).to eq({})
    end
  end
end