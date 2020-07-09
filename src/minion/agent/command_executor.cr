module Minion
  class Agent
    class CommandExecutor
      class_property? client : Minion::Client?

      def self.call(frame : Frame)
        if frame.data[0] == "external"
          command = Minion::Util.string_from_string_or_array(frame.data[1])
          argv = frame.data[2..-1]
          stdout = IO::Memory.new
          stderr = IO::Memory.new
          process = Process.new(
            command: command,
            args: argv.flatten,
            output: stdout,
            error: stderr,
            shell: true
          )
          process.wait
          unless @@client.nil?
            @@client.not_nil!.command_response(
              uuid: frame.uuid,
              stdout: stdout.to_s,
              stderr: stderr.to_s
            )
          end
        end
      end
    end
  end
end