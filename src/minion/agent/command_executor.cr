require "./version"
require "json"

module Minion
  class Agent
    class CommandExecutor
      class_property? client : Minion::Client?

      def self.call(frame : Frame)
        if frame.data[0] == "external"
          do_external_command(frame)
        else
          do_internal_command(frame)
        end
      end

      def self.do_external_command(frame)
        command, argv = get_command_arguments(frame)
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

      def self.do_internal_command(frame)
        command, argv = get_command_arguments(frame)
        case command
        when "status"
          @@client.try do |client|
            client.command_response(
              uuid: frame.uuid,
              stdout: Minion::StatsRecord.to_json
            )
          end
        when "version"
          @@client.try do |client|
            client.command_response(
              uuid: frame.uuid,
              stdout: {
                "agent"   => Minion::Agent::VERSION,
                "crystal" => Crystal::DESCRIPTION,
              }.to_json
            )
          end
        when "get-config"
          # Return the path to the current running configuration, and the contents of the configuration file.
        when "set-config"
          # Replace the configuration file currently in use with the content that were passed to the agent.
          # This will only succeed if the agent can determine that the configuration file that it was given
          # is valid.
        when "restart"
          # Restart the agent.
        when "upgrade"
          # Attempt an in-place upgrade of the agent.
        end
      end

      private def self.get_command_arguments(frame)
        command = Minion::Util.string_from_string_or_array(frame.data[1])
        argv = frame.data[2..-1]

        {command, argv}
      end
    end
  end
end
