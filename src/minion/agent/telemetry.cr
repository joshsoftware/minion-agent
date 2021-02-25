require "hardware"
require "yaml"
require "json"
require "csv"
require "crystalizer/yaml"
require "crystalizer/json"

module Minion
  class Agent
    class Telemetry
      def self.disk_usage?
        Process.find_executable("df") &&
          Process.run(command: "df", args: ["-Pk"]).success?
      rescue
        false
      end

      def self.disk_usage
        df = [] of Hash(String, String)
        if disk_usage?
          output = IO::Memory.new
          Process.run(command: "df", args: ["-Pk"], output: output)
          lines = output.to_s.chomp.split("\n")
          keys = lines[0].split.map { |k| k.downcase }
          keys.delete("on") # remove stray key since last column is "Mounted on"
          values = lines[1..-1]
          values.each do |v|
            tmp = v.split
            if tmp[0] == "map" && tmp[1] == "auto_home"
              # Delete the first index because it's a value with spaces in it
              tmp.delete_at(0)
            end
            df << Hash.zip(keys, tmp)
          end
        end
        df
      rescue
        [] of Hash(String, String)
      end

      def self.load_avg?
        File.exists?("/proc/loadavg") ||
          (Process.find_executable("sysctl") && Process.run("sysctl -n vm.loadavg", shell: true).success?)
      rescue
        false
      end

      def self.load_avg : String
        load = ""
        if load_avg?
          if File.exists?("/proc/loadavg")
            # Here we're only interested in the first number reported by loadavg
            # because we're going to report telemetry every so many seconds. That
            # means that eventually the longer-term load average statistics
            # become usless since we already have that information.
            #
            # cat /proc/loadavg
            # 0.00 0.00 0.00 1/221 4722
            values = File.read("/proc/loadavg").split(" ")
            load = values[0]?
          else
            # Without procfs, we need to rely on sysctl -n vm.loadavg
            # { 0.88 0.76 0.67 }
            sysctl = IO::Memory.new
            Process.run("sysctl -n vm.loadavg", shell: true, output: sysctl)
            values = sysctl.to_s.split(" ")
            load = values[1]?
          end
        end
        load.to_s
      end

      def self.mem_in_use?
        File.exists?("/proc/meminfo") ||
          (Process.find_executable("vm_stat") && Process.run("vm_stat", shell: true))
      end

      def self.mem_in_use
        mem = ""
        if mem_in_use?
          if File.exists?("/proc/meminfo")
            mem = Hardware::Memory.new.used.to_f.to_s # kilobytes
          else
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
            mem = (((pages_active.to_f + pages_wired.to_f + pages_compressed.to_f) * page_size.to_f) / 1024.0).to_s
          end
        end
        mem
      rescue
        ""
      end

      def self.pick_files(my_args) : Array(String)?
        cwd = Dir.current
        data = [] of String
        args = my_args.as(NamedTuple)
        pending_path = args.has_key?("pending_path") ? args["pending_path"].to_s : "."
        processed_path = args.has_key?("processed_path") ? args["processed_path"].to_s : nil
        match = args.has_key?("match") ? args["match"].to_s : "*.yml" rescue "*.yml"

        if Dir.exists?(pending_path)
          Dir.cd(pending_path)
          Dir.glob(patterns: [match], follow_symlinks: true).each do |file|
            # Process them with #{parser}
            parser = args.has_key?("parser") ? args["parser"]?.to_s : pick_parser_from_matcher(file)
            interim_data = parse_file(file, parser)
            next if interim_data.nil?

            add_interim_data(data, interim_data)
            move_file_to(processed_path, file)
          end
        end

        Dir.cd(cwd) rescue nil

        data
      end

      private def self.add_interim_data(data, interim_data)
        if interim_data.is_a?(Array)
          interim_data.each do |row|
            data << row
          end
        else
          data << interim_data.to_s
        end
      end

      def self.parse_file(file, parser = nil)
        if parser.nil?
          parser = pick_parser_from_matcher(file)
        end

        case parser
        when "yaml"
          parse_from_yaml(file)
        when "json"
          parse_from_json(file)
        when "csv"
          parse_from_csv(file)
        else
          parse_from_undefined(file)
        end
      end

      private def self.move_file_to(processed_path, file)
        if processed_path
          new_filename = File.expand_path(File.join(processed_path, file))
          Dir.mkdir_p(File.dirname(new_filename)) # ensure the destination exists
          File.rename(
            old_filename: file,
            new_filename: new_filename
          )
        end
      end

      private def self.parse_from_yaml(file)
        begin
          raw_data = File.read(file)
          parsed_yaml = Crystalizer::YAML.parse raw_data

          json_string = Crystalizer::JSON.serialize parsed_yaml

          if !YAML.parse(raw_data).as_h?
            json_string = "{ \"payload\": #{json_string}}"
          end

          json_string.chomp
        rescue e : Exception
          nil
        end
      end

      private def self.parse_from_json(file)
        json_string = File.read(file)

        if !JSON.parse(json_string).as_h?
          json_string = "{ \"payload\": #{json_string}}"
        end

        json_string.chomp
      rescue e : Exception
        nil
      end

      private def self.parse_from_csv(file) : Array(String)?
        row_jsons = [] of String

        csv = CSV.new(File.read(file), headers: true)

        while csv.next
          row_jsons << csv.row.to_h.to_json
        end

        row_jsons
      rescue e : Exception
        nil
      end

      def self.parse_from_undefined(file)
        File.read(file).chomp
      rescue e : Exception
        nil
      end

      # Takes a File matcher pattern and uses it to try to determine
      # which type of parser to use for that match.
      def self.pick_parser_from_matcher(filename)
        from_match = [
          {"**.yml", "yaml"},
          {"**.json", "json"},
          {"**.csv", "csv"},
        ].select do |pair|
          pattern, _ = pair
          File.match?(pattern: pattern, path: filename)
        end

        from_match.any? ? from_match[0].last : nil
      end

      private def self.custom?(command)
        Process.find_executable(command) || File.exists?(command)
      end

      # Execute an external command with the supplied arguments, returning that
      # command's STDOUT.
      def self.custom(telemetry)
        if custom?(telemetry.command)
          output = IO::Memory.new
          Process.run(%(#{telemetry.command} "${@}"), shell: true, output: output, args: telemetry.args)
          output.to_s.chomp
        else
          ""
        end
      end
    end
  end
end
