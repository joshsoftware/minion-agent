require "hardware"

module Minion
  class Agent
    class Telemetry
      def self.mem_in_use
        begin
          mem = Hardware::Memory.new
          return mem.used.to_f # kilobytes
        rescue exception
          # If no /proc, we're probably on MacOS, so fall back to sysctl/vm_stat
          # NOTE: This is for MacOS. I'm not sure on the accuracy of how I'm
          # measuring this, so this can be a "TODO" to clean this up later with
          # better measurements from vm_stat.
          cmd = "vm_stat"
          vm_stat = IO::Memory.new
          Process.run(cmd, shell: true, output: vm_stat)
          pages_active     : Int32 = vm_stat.to_s.match(/Pages active\:\s*(\d*)/).
            not_nil![1].to_i.not_nil!
          page_size        : Int32 = vm_stat.to_s.match(/\(page size of (\d*) bytes\)/).
            not_nil![1].to_i.not_nil!
          pages_wired      : Int32 = vm_stat.to_s.match(/Pages wired down\:\s*(\d*)/).
            not_nil![1].to_i.not_nil!
          pages_compressed : Int32 = vm_stat.to_s.match(/Pages stored in compressor\:\s*(\d*)/).
            not_nil![1].to_i.not_nil!

          # No we multiply the number of pages (active and wired) by the page
          # size to find out roughly how many bytes of memory are in use. We
          # could get maximum memory from sysctl -n hw.memsize but it's not as
          # important as knowing how much is *in use* and seeing that trend.

          max_mem = IO::Memory.new
          Process.run("sysctl -n hw.memsize", shell: true, output: max_mem)
          max_mem = max_mem.to_s.to_f
          # Return used memory in kilobytes
          used_mem : Float64 = ((pages_active.to_f + pages_wired.to_f + pages_compressed.to_f) * page_size.to_f) / 1024.0
          return used_mem
        end
      end
    end
  end
end
