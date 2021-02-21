require "./spec_helper"
require "json"

describe Minion::Agent::Stats do
  it "creates a functional Stats object" do
    stats = Minion::Agent::Stats.new

    stats.start.to_unix_f.should be <= Time.utc.to_unix_f
    stats.start.to_unix_f.should be > (Time.utc.to_unix_f - 1)
    stats.start_monotonic.should be <= Time.monotonic

    stats.connections.should eq 0_u64
    stats.commands_received.should eq 0_u64
    stats.commands_external.should eq 0_u64
    stats.commands_internal.should eq 0_u64
    stats.commands_error.should eq 0_u64
    stats.logs_sent.should eq 0_u64
    stats.telemetries_sent.should eq 0_u64

    stats.increment_connections
    stats.increment_commands_received
    stats.increment_commands_external
    stats.increment_commands_internal
    stats.increment_commands_error
    stats.increment_logs_sent
    stats.increment_telemetries_sent

    stats.connections.should eq 1_u64
    stats.commands_received.should eq 1_u64
    stats.commands_external.should eq 1_u64
    stats.commands_internal.should eq 1_u64
    stats.commands_error.should eq 1_u64
    stats.logs_sent.should eq 1_u64
    stats.telemetries_sent.should eq 1_u64
  end

  it "gets a JSON representation of total stats" do
    stats = Minion::Agent::Stats.new

    stats_json = stats.to_json

    sj = JSON.parse stats_json
  end
end
