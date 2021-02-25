require "./spec_helper"

describe Minion::Agent::Telemetry do
  it "can determine whether disk usage can be determined" do
    Minion::Agent::Telemetry.disk_usage?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.disk_usage?
    it "can determine disk usage" do
      disk_data = Minion::Agent::Telemetry.disk_usage
      disk_data.any?.should be_true
    end
  else
    pending "The Telemetry class doesn't know how to determine disk usage on this platform"
  end

  it "can determine whether load average can be determined" do
    Minion::Agent::Telemetry.load_avg?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.load_avg?
    load_data = Minion::Agent::Telemetry.load_avg
    load_data.empty?.should be_false
  else
    pending "The Telemetry class doesn't know how to determine load average on this platform."
  end

  it "can determine whether memory in use can be determined" do
    Minion::Agent::Telemetry.mem_in_use?.should be_a(Bool)
  end

  if Minion::Agent::Telemetry.mem_in_use?
    mem_data = Minion::Agent::Telemetry.mem_in_use
    mem_data.empty?.should be_false
  else
    pending "The Telememtry class doesn't know how to determine memory in use"
  end

  it "can define custom telemetry" do
    yaml = <<-EYAML
      name: "name"
      command: "runme"
      args:
        - 1
        - 2
        - 3
      interval: 59
    EYAML

    custom_config = Minion::Config::CustomTelemetry.from_yaml(yaml)

    custom_config.name.should eq "name"
    custom_config.command.should eq "runme"
    custom_config.args.should eq %w{1 2 3}
    custom_config.interval.should eq 59

    yaml = <<-EYAML
      name: "custom-success"
      command: "ls"
      args:
        - /
      interval: 300
    EYAML

    custom_config = Minion::Config::CustomTelemetry.from_yaml(yaml)
    custom_data = Minion::Agent::Telemetry.custom(custom_config)
    custom_data.empty?.should be_false
  end

  it "can match a YAML filename to the YAML parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("i_am_a_yaml_file.yml")
      .should eq "yaml"
  end

  it "can match a YAML filename that is deeper in the path structure to the YAML parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("foo/i_am_a_yaml_file.yml")
      .should eq "yaml"
  end

  it "can match a JSON filename to the JSON parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("i_am_a_json_file.json")
      .should eq "json"
  end

  it "can match a JSON filename that is deeper in the path structure to the JSON parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("foo/i_am_a_json_file.json")
      .should eq "json"
  end

  it "can match a CSV filename to the CSV parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("i_am_a_csv_file.csv")
      .should eq "csv"
  end

  it "can match a CSV filename that is deeper in the path structure to the CSV parser" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("foo/i_am_a_csv_file.csv")
      .should eq "csv"
  end

  it "returns nil for the parser if the filename doesn't fit the available patterns" do
    Minion::Agent::Telemetry.pick_parser_from_matcher("i_am_a_unknown_file.toml")
      .should be_nil
  end

  it "can parse a JSON file and get a JSON formatted string" do
    json_string = Minion::Agent::Telemetry.parse_file(
      File.expand_path(File.join(__DIR__, "data", "sample.json"))
    )

    json_string.should eq <<-JSON
    {
      "foo": {
        "bar": {
          "baz": [
            "qux",
            "fox"
          ]
        }
      }
    }
    JSON
  end

  it "can parse a YAML file and get a YAML formatted string" do
    json_string = Minion::Agent::Telemetry.parse_file(
      File.expand_path(File.join(__DIR__, "data", "sample.yml")))

    json_string.should eq <<-JSON
    {
      "foo": {
        "bar": {
          "baz": [
            "qux",
            "fox"
          ]
        }
      }
    }
    JSON
  end

  it "can parse a CSV file and get a CSV formatted string" do
    json_strings = Minion::Agent::Telemetry.parse_file(
      File.expand_path(File.join(__DIR__, "data", "sample.csv"))
    )
    if !json_strings.nil?
      json_strings[0].should eq %({"one":"1","two":"2","three":"3"})
      json_strings[1].should eq %({"one":"a","two":"b","three":"c"})
      json_strings[2].should eq %({"one":"you","two":"and","three":"me"})
    end
  end

  it "it can pull the data from a file of unknown format" do
    data = Minion::Agent::Telemetry.parse_file(
      File.expand_path(File.join(__DIR__, "data", "sample.txt"))
    )

    if !data.nil?
      data.should eq "I am just a random plonk of text."
    end
  end

  it "can pickup files in one directory, process them, and move them to another directory" do
    data_path = File.expand_path(File.join(__DIR__, "data"))
    from_path = File.expand_path(File.join(__DIR__, "from"))
    to_path = File.expand_path(File.join(__DIR__, "to"))

    # Setup our files to pickup.
    Dir.glob(File.join(data_path, "*")).each do |file|
      File.copy(src: file, dst: File.join(from_path, File.basename(file)))
    end

    # Ensure that our destination is empty of the files that are to be picked up.
    Dir.glob(File.join(to_path, "*")).each do |file|
      File.delete(path: file)
    end

    all_data = Minion::Agent::Telemetry.pick_files({
      pending_path:   from_path,
      processed_path: to_path,
      match:          "*",
    })

    all_data.size.should eq 6

    all_data.select do |row|
      row == <<-JSON
      {
        "foo": {
          "bar": {
            "baz": [
              "qux",
              "fox"
            ]
          }
        }
      }
      JSON
    end.size.should eq 2

    all_data.select do |row|
      row == "I am just a random plonk of text."
    end.size.should eq 1

    all_data.select do |row|
      row == %({"one":"1","two":"2","three":"3"}) ||
      row == %({"one":"a","two":"b","three":"c"}) ||
      row == %({"one":"you","two":"and","three":"me"})
    end.size.should eq 3

    # All of the files were moved?
    Dir.glob(File.join(to_path, "*")).size.should eq 4

    # Cleanup
    Dir.glob(File.join(to_path, "*")).each do |file|
      File.delete(file)
    end

  end
end
