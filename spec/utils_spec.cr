require "./spec_helper"

describe Minion::Agent::Utils do
  it "can determine the OS that we are running on" do
    Minion::Agent::Utils.get_os.should be_truthy
  end
end
