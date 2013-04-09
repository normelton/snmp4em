require "spec_helpers.rb"

describe "When performing a single SNMPv2 GETBULK request" do
  it "should fetch the next ten values" do
    @snmp_v2.getbulk("1.9.9.6.1").expect do |response|
      response.should have(1).item
      response["1.9.9.6.1"].should == {
        "1.9.9.6.1.1" => "1-A",
        "1.9.9.6.1.2" => "1-B",
        "1.9.9.6.1.3" => "1-C",
        "1.9.9.6.1.4" => "1-D",
        "1.9.9.6.2.1" => "2-A",
        "1.9.9.6.2.2" => "2-B",
        "1.9.9.6.2.3" => "2-C",
        "1.9.9.6.2.4" => "2-D",
        "1.9.9.6.3.1" => "3-A",
        "1.9.9.6.3.2" => "3-B"
      }
    end
  end

  it "should fetch four values when limited" do
    @snmp_v2.getbulk("1.9.9.6.1", :max_results => 4).expect do |response|
      response.should have(1).item
      response["1.9.9.6.1"].should == {
        "1.9.9.6.1.1" => "1-A",
        "1.9.9.6.1.2" => "1-B",
        "1.9.9.6.1.3" => "1-C",
        "1.9.9.6.1.4" => "1-D"
      }
    end
  end

  it "should fetch only four values if it reaches the end of the MIB" do
    @snmp_v2.getbulk("1.9.9.6.3").expect do |response|
      response.should have(1).item
      response["1.9.9.6.3"].should == {
        "1.9.9.6.3.1" => "3-A",
        "1.9.9.6.3.2" => "3-B",
        "1.9.9.6.3.3" => "3-C",
        "1.9.9.6.3.4" => "3-D"
      }
    end
  end

  it "should return an empty hash if the requested OID is past the end of the MIB" do
    @snmp_v2.getbulk("1.10.10").expect do |response|
      response.should have(1).item
      response["1.10.10"].should == {}
    end
  end
end

describe "When performing multiple SNMPv2 GETBULK requests simultaneously" do
  it "should fetch two values correctly" do
    @snmp_v2.getbulk(["1.9.9.6.1", "1.9.9.6.2"]).expect do |response|
      response.should have(2).items

      response["1.9.9.6.1"].should == {
        "1.9.9.6.1.1" => "1-A",
        "1.9.9.6.1.2" => "1-B",
        "1.9.9.6.1.3" => "1-C",
        "1.9.9.6.1.4" => "1-D",
        "1.9.9.6.2.1" => "2-A",
        "1.9.9.6.2.2" => "2-B",
        "1.9.9.6.2.3" => "2-C",
        "1.9.9.6.2.4" => "2-D",
        "1.9.9.6.3.1" => "3-A",
        "1.9.9.6.3.2" => "3-B"
      }

      response["1.9.9.6.2"].should == {
        "1.9.9.6.2.1" => "2-A",
        "1.9.9.6.2.2" => "2-B",
        "1.9.9.6.2.3" => "2-C",
        "1.9.9.6.2.4" => "2-D",
        "1.9.9.6.3.1" => "3-A",
        "1.9.9.6.3.2" => "3-B",
        "1.9.9.6.3.3" => "3-C",
        "1.9.9.6.3.4" => "3-D"
      }
    end
  end

  it "should honor the non_repeaters value" do
    @snmp_v2.getbulk(["1.9.9.6.1", "1.9.9.6.2"], :non_repeaters => 1).expect do |response|
      response.should have(2).items

      response["1.9.9.6.1"].should == {
        "1.9.9.6.1.1" => "1-A"
      }

      response["1.9.9.6.2"].should == {
        "1.9.9.6.2.1" => "2-A",
        "1.9.9.6.2.2" => "2-B",
        "1.9.9.6.2.3" => "2-C",
        "1.9.9.6.2.4" => "2-D",
        "1.9.9.6.3.1" => "3-A",
        "1.9.9.6.3.2" => "3-B",
        "1.9.9.6.3.3" => "3-C",
        "1.9.9.6.3.4" => "3-D"
      }
    end
  end
end