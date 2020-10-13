require "../src/minion/monkeys/file_info"
require "./spec_helper"

describe Crystal::System::FileInfo do

  it "can access the creation time of a file" do
    File.info("README.md").creation_time.class.should eq Time
  end

  it "can access the raw file stat information for a file" do
    File.info("README.md").raw.st_ctim.class.should eq LibC::Timespec
  end

end
