require "spec_helpers.rb"

describe "When receiving an SNMPv1 trap" do
  it "should receive the trap" do
    manager = SNMP4EM::NotificationManager.new(:port => 1621)

    manager.on_trap do |trap|
      trap.should be_a(SNMP::SNMPv1_Trap)
      trap.enterprise.to_s.should == "1.2.3"
      trap.generic_trap.should == :linkUp
      trap.specific_trap.should == 0

      EM.stop
    end

    `snmptrap -v 1 -c public --noPersistentLoad=yes localhost:1621 1.2.3 localhost 3 0 ''`
  end
end