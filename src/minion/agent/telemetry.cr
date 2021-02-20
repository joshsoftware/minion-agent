require "hardware"
require "yaml"
require "json"
require "csv"
require "crystalizer/yaml"
require "crystalizer/json"

module Minion
  class Agent
    class Telemetry
      def self.disk_usage
        output = IO::Memory.new
        Process.run(command: "df", args: ["-Pk"], output: output)
        lines = output.to_s.chomp.split("\n")
        keys = lines[0].split.map { |k| k.downcase }
        keys.delete("on") # remove stray key since last column is "Mounted on"
        values = lines[1..-1]
        df = [] of Hash(String, String)
        values.each do |v|
          tmp = v.split
          if tmp[0] == "map" && tmp[1] == "auto_home"
            # Delete the first index because it's a value with spaces in it
            tmp.delete_at(0)
          end
          df << Hash.zip(keys, tmp)
        end

        df
      rescue exception
        [] of Hash(String, String)
      end

      def self.load_avg
        # Here we're only interested in the first number reported by loadavg
        # because we're going to report telemetry every so many seconds. That
        # means that eventually the longer-term load average statistics
        # become usless since we already have that information.
        #
        # cat /proc/loadavg
        # 0.00 0.00 0.00 1/221 4722
        File.read("/proc/loadavg").split(" ").not_nil![0]
      rescue exception
        # Without procfs, we need to rely on sysctl -n vm.loadavg
        # { 0.88 0.76 0.67 }
        sysctl = IO::Memory.new
        Process.run("sysctl -n vm.loadavg", shell: true, output: sysctl)
        sysctl.to_s.split(" ").not_nil![1]
      end

      def self.mem_in_use
        Hardware::Memory.new.used.to_f # kilobytes
      rescue exception
        # If no /proc, we're probably on MacOS, so fall back to sysctl/vm_stat
        # NOTE: This is for MacOS. I'm not sure on the accuracy of how I'm
        # measuring this, so this can be a "TODO" to clean this up later with
        # better measurements from vm_stat.
        cmd = "vm_stat"
        vm_stat = IO::Memory.new
        Process.run(cmd, shell: true, output: vm_stat)
        pages_active : Int32 = vm_stat.to_s.match(/Pages active\:\s*(\d*)/)
          .not_nil![1].to_i.not_nil!
        page_size : Int32 = vm_stat.to_s.match(/\(page size of (\d*) bytes\)/)
          .not_nil![1].to_i.not_nil!
        pages_wired : Int32 = vm_stat.to_s.match(/Pages wired down\:\s*(\d*)/)
          .not_nil![1].to_i.not_nil!
        pages_compressed : Int32 = vm_stat.to_s.match(/Pages stored in compressor\:\s*(\d*)/)
          .not_nil![1].to_i.not_nil!

        # Now we multiply the number of pages (active and wired) by the page
        # size to find out roughly how many bytes of memory are in use. We
        # could get maximum memory from sysctl -n hw.memsize but it's not as
        # important as knowing how much is *in use* and seeing that trend.

        # Return used memory in kilobytes
        ((pages_active.to_f + pages_wired.to_f + pages_compressed.to_f) * page_size.to_f) / 1024.0
      end

      def self.pick_files(my_args)
        args = my_args.as(Hash)
        pending_path = args.has_key?("pending_path") ? args["pending_path"].to_s : "."
        processed_path = args.has_key?("processed_path") ? args["processed_path"].to_s : nil
        match = args.has_key?("match") ? args["match"].to_s : "*.yml" rescue "*.yml"
        parser = args.has_key?("parser") ? args["parser"].to_s : pick_parser_from_matcher(match)

        # Iterate through all files in the #{pending_path} to find
        # those that match #{match}.
        cwd = Dir.current

        data = [] of String

        if Dir.exists?(pending_path)
          Dir.cd(pending_path)
          Dir.glob(patterns: [match], follow_symlinks: true).each do |file|
            # Process them with #{parser}
            puts "Globber found #{file}"
            interim_data = case parser
                           when "yaml"
                             parse_from_yaml(file)
                           when "json"
                             parse_from_json(file)
                           when "csv"
                             parse_from_csv(file)
                           else
                             parse_from_undefined(file)
                           end
            next if interim_data.nil?

            if interim_data.is_a?(Array)
              interim_data.each do |row|
                data << row
              end
            else
              data << interim_data.to_s
            end
            # Move processed file to #{processed_path}
          end
        end

        Dir.cd(cwd) rescue nil

        data
        # Return processed data
      end

      def self.parse_from_yaml(file)
        puts "Reading #{file}"
        begin
          raw_data = File.read(file)
          parsed_yaml = Crystalizer::YAML.parse raw_data

          json_string = Crystalizer::JSON.serialize parsed_yaml

          if !YAML.parse(raw_data).as_h?
            json_string = "{ \"payload\": #{json_string}}"
          end

          puts "Sending #{json_string}"
          json_string
        rescue e : Exception
          nil
        end
      end

      def self.parse_from_json(file)
        begin
          json_string = File.read(file)

          if !JSON.parse(json_string).as_h?
            json_string = "{ \"payload\": #{json_string}}"
          end

          json_string
        rescue e : Exception
          nil
        end
      end

      def self.parse_from_csv(file)
        row_jsons = [] of String

        begin
          csv = CSV.new(File.read(file), headers: true)

          while csv.next
            row_jsons << csv.row.to_h.to_json
          end
        rescue e : Exception
          nil
        end
        row_jsons
      end

      def self.parse_from_undefined(file)
        begin
          File.read(file)
        rescue e : Exception
          nil
        end
      end

      def self.pick_parser_from_matcher(match)
        from_match = [
          {"foo.yml", "yaml"},
          {"foo.json", "json"},
          {"foo.csv", "csv"},
        ].select do |pair|
          filename, _ = pair
          File.match?(pattern: match, path: filename)
        end

        from_match.any? ? from_match[0].last : nil
      end

      # Execute an external command with the supplied arguments, returning that
      # command's STDOUT.
      def self.custom(telemetry)
        if File.exists?(telemetry.command) || Process.find_executable(telemetry.command)
          output = IO::Memory.new
          Process.run(%(#{telemetry.command} "${@}"), shell: true, output: output, args: telemetry.args)
          output.to_s.chomp
        else
          puts "Could not find #{telemetry.command}"
        end
      end
    end
  end
end
