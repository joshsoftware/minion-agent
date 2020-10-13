require "./spec_helper"

describe Minion::Timer do
  it "creates a one-shot timer" do
    wait = Channel(Int32).new
    start = Time.monotonic
    timer = Minion::Timer.new do
      wait.send(7)
    end
    num = wait.receive
    finish = Time.monotonic
    num.should eq(7)
    ((finish - start).to_f > 1.0).should be_true
  end

  it "creates a one-shot timer with a configurable interval" do
    wait = Channel(Int32).new
    start = Time.monotonic
    timer = Minion::Timer.new(interval: 0.1) do
      wait.send(7)
    end
    num = wait.receive
    finish = Time.monotonic
    num.should eq(7)
    ((finish - start).to_f > 0.1).should be_true
  end

  it "creates a periodic timer" do
    wait = Channel(Int32).new
    start = Time.monotonic
    n = 0
    timer = Minion::Timer.new(interval: 0.1, periodic: true) do |tmr|
      n += 1
      wait.send n
      tmr.cancel if n == 3
    end

    timer.periodic?.should be_true
    num = 0
    3.times { num = wait.receive }
    finish = Time.monotonic
    num.should eq(3)
    ((finish - start).to_f > 0.3).should be_true
  end

  it "cancels and resumes a timer" do
    wait = Channel(Int32).new
    start = Time.monotonic
    n = 0
    timer = Minion::Timer.new(interval: 0.1, periodic: true) do |tmr|
      n += 1
      wait.send n
      tmr.cancel if n % 3 == 0
    end

    num = 0
    3.times { num = wait.receive }
    timer.canceled?.should be_true
    timer.resume
    3.times { num = wait.receive }
    finish = Time.monotonic
    num.should eq(6)
    ((finish - start).to_f > 0.6).should be_true
  end
end
