require "./spec_helper"

describe Minion::Agent::Telemetry do
  it "can determine whether disk usage can be determined" do
    Minion::Agent::Telemetry.disk_usage?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.disk_usage?
    it "can determine disk usage" do
      data = Minion::Agent::Telemetry.disk_usage
      data.any?.should be_true
    end
  else
    pending "The Telemetry class doesn't know how to determine disk usage on this platform"
  end

  it "can determine whether load average can be determined" do
    Minion::Agent::Telemetry.load_avg?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.load_avg?
    data = Minion::Agent::Telemetry.load_avg
    data.empty?.should be_false
  else
    pending "The Telemetry class doesn't know how to determine load average on this platform."
  end

  it "can determine whether memory in use can be determined" do
    Minion::Agent::Telemetry.mem_in_use?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.mem_in_use?
    data = Minion::Agent::Telemetry.mem_in_use
    data.empty?.should be_false
  else
    pending "The Telememtry class doesn't know how to determine memory in use"
  end
end
