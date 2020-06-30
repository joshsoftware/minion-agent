module Minion
  class Agent
    def self.upgrade
      # 0. Define the root location for /opt/minion or wherever minion's install
      #    directory is located.
      # TODO: Is there a cleaner way to auto-discover this path?
      exec_path : String =  Process.executable_path.not_nil!
      filename : String = exec_path.match(/.*(\/.*)/).not_nil![1]
      dir = exec_path.gsub(/#{filename}/, "")

      # 1. Query the API for the latest version.
      # 2. Download that version to PWD/versions/minion-VERSION
      # 3. Run PWD/versions/minion-VERSION -t CONFIG=#{ENV["CONFIG"]}
      # 4. If it returns exit code zero (0), proceed, else log that upgrade
      #    failed along with the STDERR output from that run
      # 5. Symlink PWD/bin/minion-agent to PWD/versions/minion-VERSION
      # 6. Replace this running process with bin/minion-agent (Process.exec)
    end
  end
end
