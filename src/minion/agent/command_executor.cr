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
          Minion::ConfigSource.rewind
          mcs = Minion::ConfigSource
          @@client.try do |client|
            client.command_response(
              uuid: frame.uuid,
              stdout: {
                "path"   => mcs.responds_to?(:path) ? mcs.path : "",
                "config" => Minion::ConfigSource.gets_to_end,
              }.to_json
            )
          end
        when "validate-config"
          # Write the given configuration file, and then attempt to parse it. Return the parsed configuration
          # file, which the origin can compare with what was sent for final validation.

          error = ""
          cfg = ""
          begin
            cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"])).to_yaml
          rescue ex
            error = ex.to_s
          end
          @@client.try do |client|
            client.command_response(
              uuid: frame.uuid,
              stdout: cfg,
              stderr: error
            )
          end
        when "set-config"
          # Replace the configuration file currently in use with the content that were passed to the agent.
          # This will only succeed if the agent can determine that the configuration file that it was given
          # is valid.
          cfg_text = frame.data[0]

          cfg = ""
          error = false
          begin
            cfg = Minion::Config.from_yaml(cfg_text.to_s)
          rescue ex
            error = ex.to_s
          end

          if error
            @@client.try do |client|
              client.command_response(
                uuid: frame.uuid,
                stdout: "",
                stderr: error ? error.to_s : ""
              )
            end
            return nil
          end

          cfg = cfg.as(Minion::Config)
          begin
            ss = Minion::Client.new(
              host: cfg.streamserver_host,
              port: cfg.streamserver_port,
              group: cfg.group_id,
              server: cfg.server_id,
              key: cfg.group_key,
            )
          rescue ex
            error = ex.to_s
          end

          if error
            @@client.try do |client|
              client.command_response(
                uuid: frame.uuid,
                stdout: "",
                stderr: error ? error.to_s : ""
              )
            end
            return nil
          end

          # The config parsed OK, and a connection could be made back to the streamserver using it,
          # so it is probably good.  Write it.
          File.open("w", ENV["CONFIG"]) do |fh|
            fh.write cfg_text.to_s.to_slice
          end

          @@client.try do |client|
            client.command_response(
              uuid: frame.uuid,
              stdout: "Config written to #{ENV["CONFIG"]} at #{Time.utc}"
            )
          end
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
