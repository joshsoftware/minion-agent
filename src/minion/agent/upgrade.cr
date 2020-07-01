require "http/client"
require "json"
require "./upgrade_data"

module Minion
  class Agent
    class FailedToUpgrade < Exception
      def initialize(err : Exception)
        super("Failed to upgrade the minion agent: #{err}")
      end
    end

    def self.upgrade!
      # Try to get the config and fail if you can't
      begin
        cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"]))
      rescue exception
        raise FailedToUpgrade.new(exception)
      end


      # 0. Define the root location for /opt/minion or wherever minion's install
      #    directory is located.
      # TODO: Is there a cleaner way to auto-discover this path?
      exec_path : String =  Process.executable_path.not_nil!
      filename : String = exec_path.match(/.*(\/.*)/).not_nil![1]
      root_dir = exec_path.sub(/#{filename}/, "")

      # 1. Query the API for the latest version.
      begin
        upgrade_data = Minion::Agent::UpgradeData.from_json(HTTP::Client.get(cfg.upgrade).body)
      rescue exception
        raise FailedToUpgrade.new(exception)
      end

      # 2. Download that version to PWD/versions/minion-VERSION
      #    a) Check if versions/ subdir exists
      if !Dir.exists?(File.join(root_dir, "versions"))
        #    b) Create it if not
        Dir.mkdir(File.join(root_dir, "versions"))
      end

      #    c) Download and save the file
      filename = File.join(root_dir, "versions", "minion-agent-#{upgrade_data.latest_version}")
      File.open(filename, "ab") do |fh|
        HTTP::Client.get(upgrade_data.download_url) do |response|
          if response.status_code == 200
            fh.write response.body_io.gets_to_end.to_slice
          end
        end
      end
      #    d) Run a shasum on the file
      #    e) Compare shasum to upgrade_data shasum
      # 3. Run PWD/versions/minion-VERSION -t CONFIG=#{ENV["CONFIG"]}
      # 4. If it returns exit code zero (0), proceed, else log that upgrade
      #    failed along with the STDERR output from that run
      # 5. Symlink PWD/bin/minion-agent to PWD/versions/minion-VERSION
      # 6. Replace this running process with bin/minion-agent (Process.exec)
    end
  end
end
