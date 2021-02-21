require "./spec_helper"

describe Minion::Agent::Telemetry do
  if Process.find_executable("df")
    it "can determine disk usage" do
      data = Minion::Agent::Telemetry.disk_usage
      data.any?.should be_true
    end
  else
    pending "df is required to determine disk usage"
  end

  
end