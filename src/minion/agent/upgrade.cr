require "http/client"
require "json"
require "digest/md5"
require "./upgrade_data"

module Minion
  class Agent
    class FailedToUpgrade < Exception
      def initialize(err)
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
      File.open(filename, "wb") do |fh|
        HTTP::Client.get(upgrade_data.download_url) do |response|
          if response.status_code == 200
            fh.write response.body_io.gets_to_end.to_slice
          end
        end
      end
      #    d) Run a shasum on the file
      md5sum = Digest::MD5.hexdigest(File.read(filename))
      puts "Downloaded agent MD5 Sum: #{md5sum}"
      puts "Published MD5 Sum: #{upgrade_data.md5}"
      #    e) Compare shasum to upgrade_data shasum
      if md5sum != upgrade_data.md5
        raise FailedToUpgrade.new("MD5 sums do not match; try again")
        exit 1
      end

      # 3. Run PWD/versions/minion-VERSION -t CONFIG=#{ENV["CONFIG"]}
      output = IO::Memory.new
      exit_code = Process.run("CONFIG=#{ENV["CONFIG"]} #{filename} -t", shell: true, output: output)

      # 4. If it returns exit code zero (0), proceed, else log that upgrade
      #    failed along with the STDERR output from that run
      if !exit_code.success?
        raise FailedToUpgrade.new("Test of new agent version failed, halting upgrade\n\n#{output}")
        exit 1
      end

      # 5. Symlink PWD/bin/minion-agent to PWD/versions/minion-VERSION
      agent_filename = File.join(root_dir, "bin", "minion-agent")
      if File.exists?(agent_filename)
        # Remove the symlink so we can recreate it
        File.new(filename: agent_filename).delete
      end
      # output = IO::Memory.new
      # unless Process.run("ln -s #{filename} #{root_dir}/bin/minion-agent", shell: true, output: output).success?
      #   \n\n#{output}")
      #   exit 1
      # end

      begin
        File.symlink(old_path: filename, new_path: agent_filename)
      rescue exception
        raise FailedToUpgrade.new("Could not symlink #{filename} to #{agent_filename}")
        exit 1
      end

      # 6. Replace this running process with bin/minion-agent (Process.exec)
      env = {"CONFIG" => ENV["CONFIG"]}
      Process.exec("#{root_dir}/bin/minion-agent", shell: true, env: env)
    end
  end
end
