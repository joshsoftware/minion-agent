require "./spec_helper"

describe Minion::ParseDate do
  it "parses HTTP dates" do
    dt = Minion::ParseDate.parse("Sun, 14 Feb 2016 21:00:00 GMT")
    dt.to_s.should eq("2016-02-14 21:00:00 UTC")
    dt = Minion::ParseDate.parse("Sunday, 14-Feb-16 21:00:00 GMT")
    dt.to_s.should eq("2016-02-14 21:00:00 UTC")
    dt = Minion::ParseDate.parse("Sun Feb 14 21:00:00 2016")
    dt.to_s.should eq("2016-02-14 21:00:00 UTC")
  end

  it "parses ISO_8601 dates and times" do
    dt = Minion::ParseDate.parse("1994-11-05T08:15:30-05:00")
    dt.to_s.should eq("1994-11-05 08:15:30 -05:00")
    dt = Minion::ParseDate.parse("1994-11-05T13:15:30Z")
    dt.to_s.should eq("1994-11-05 13:15:30 UTC")
    dt = Minion::ParseDate.parse("2020-07-20")
    dt.to_s.should eq("2020-07-20 00:00:00 UTC")
  end

  it "parses RFC 2822 dates" do
    dt = Minion::ParseDate.parse("Thu, 13 Feb 1969 23:32:54 -0330")
    dt.to_s.should eq("1969-02-13 23:32:54 -03:30")
  end

  it "parses RFC 3339 dates" do
    dt = Minion::ParseDate.parse("1985-04-12T23:20:50.52Z")
    dt.to_s.should eq("1985-04-12 23:20:50 UTC")
    dt = Minion::ParseDate.parse("1996-12-19T16:39:57-08:00")
    dt.to_s.should eq("1996-12-19 16:39:57 -08:00")
    dt = Minion::ParseDate.parse("1990-12-31T15:59:60-08:00")
    dt.to_s.should eq("1990-12-31 00:00:00 UTC")
    dt = Minion::ParseDate.parse("1937-01-01T12:00:27.87+00:20")
    dt.to_s.should eq("1937-01-01 12:00:27 +00:20")
  end

  it "parses YAML dates" do
    dt = Minion::ParseDate.parse("2001-12-14t21:59:43.10-05:00")
    dt.to_s.should eq("2001-12-14 21:59:43 -05:00")
    dt = Minion::ParseDate.parse("2008-04-17 08:55:11.842682 -06:00")
    dt.to_s.should eq("2008-04-17 08:55:11 -06:00")
    dt = Minion::ParseDate.parse("2001-12-14 21:59:43.10 -5")
    dt.to_s.should eq("2001-12-14 21:59:43 -05:00")
    dt = Minion::ParseDate.parse("2001-12-15 2:59:43.10")
    dt.to_s.should eq("2001-12-15 02:59:43 UTC")
  end

  it "parses US Military style dates" do
    dt = Minion::ParseDate.parse("20 Jul 2020")
    dt.to_s.should eq("2020-07-20 00:00:00 UTC")
    dt = Minion::ParseDate.parse("20 July 2020")
    dt.to_s.should eq("2020-07-20 00:00:00 UTC")
    dt = Minion::ParseDate.parse("20 JUL 2020")
    dt.to_s.should eq("2020-07-20 00:00:00 UTC")
    dt = Minion::ParseDate.parse("20JUL2020")
    dt.to_s.should eq("2020-07-20 00:00:00 UTC")
    dt = Minion::ParseDate.parse("20 1946 JUL 2020")
    dt.to_s.should eq("2020-07-20 19:46:00 UTC")
    dt = Minion::ParseDate.parse("201947JUL2020")
    dt.to_s.should eq("2020-07-20 19:47:00 UTC")
    dt = Minion::ParseDate.parse("20 194637 JUL 2020")
    dt.to_s.should eq("2020-07-20 19:46:37 UTC")
    dt = Minion::ParseDate.parse("20194638JUL2020")
    dt.to_s.should eq("2020-07-20 19:46:38 UTC")
  end

  it "returns nil to nil or unparseable junk" do
    dt = Minion::ParseDate.parse(nil)
    dt.should be_nil
    dt = Minion::ParseDate.parse("blahblah not a date")
    dt.should be_nil
  end
end
