require "./spec_helper"

WELL_FORMED = /^([0-9a-f]{12})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})/

describe Minion::UUID do
  it "will generate a valid random UUID" do
    uuid = Minion::UUID.new
    uuid.to_s.should match(WELL_FORMED)
  end

  it "can be initialized with a previously generated UUID string" do
    pre = Minion::UUID.new
    post = Minion::UUID.new(pre.to_s)
    post.to_s.should match(WELL_FORMED)
  end

  it "can be initialized with a previously generated UUID object" do
    pre = Minion::UUID.new
    post = Minion::UUID.new(pre)
    post.to_s.should match(WELL_FORMED)
  end
end
