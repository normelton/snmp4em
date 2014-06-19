require "spec_helpers.rb"

describe "When performing a fibered SNMPv2 GET request" do
  it "should fetch the correct value" do
    f = Fiber.new do
      response = @snmp_v1_fiber.get("1.9.9.1.1")
      expect(response).to eq({"1.9.9.1.1"=>"AAA"})
      EM.stop
    end

    f.resume
  end
end
