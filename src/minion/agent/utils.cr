module Minion
  class Agent
    class Utils
      # Returns the OS in use based on the output of `uname`. Generally will
      # be one of Darwin or Linux, but if uname isn't found on the system, we
      # assume we're on Windows.
      def self.get_os : String
        if Process.find_executable("uname")
          output = IO::Memory.new
          begin
            Process.run(command: "uname", output: output)
            output.to_s
          rescue exception
            "Windows"
          end
        else
          "Windows"
        end
      end
    end
  end
end
