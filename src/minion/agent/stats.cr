require "json"

module Minion
  class Agent
    class Stats
      getter start : Time
      getter start_monotonic : Time::Span
      getter connections : UInt64
      getter commands_received : UInt64
      getter commands_external : UInt64
      getter commands_internal : UInt64
      getter commands_error : UInt64
      getter logs_sent : UInt64
      getter telemetries_sent : UInt64

      def initialize
        @start, @start_monotonic = get_times
        @connections = 0_u64
        @commands_received = 0_u64
        @commands_external = 0_u64
        @commands_internal = 0_u64
        @commands_error = 0_u64
        @logs_sent = 0_u64
        @telemetries_sent = 0_u64
      end

      def set_start_time
        @start, @start_monotonic = get_times
      end

      def get_times
        {Time.utc, Time.monotonic}
      end

      def increment_connections
        @connections += 1
      end

      def increment_commands_received
        @commands_received += 1
      end

      def increment_commands_external
        @commands_external += 1
      end

      def increment_commands_internal
        @commands_internal += 1
      end

      def increment_commands_error
        @commands_error += 1
      end

      def increment_logs_sent
        @logs_sent += 1
      end

      def increment_telemetries_sent
        @telemetries_sent += 1
      end

      def to_json
        gcs = GC.stats
        {
          start:             @start,
          uptime:            (Time.monotonic - @start_monotonic).total_seconds,
          connections:       @connections,
          commands_received: @commands_received,
          commands_external: @commands_external,
          commands_internal: @commands_internal,
          commands_error:    @commands_error,
          logs_sent:         @logs_sent,
          telemetry:         @telemetries_sent,
          now:               Time.utc,
          heap_size:         gcs.heap_size,
          free_bytes:        gcs.free_bytes,
          unmapped_bytes:    gcs.unmapped_bytes,
          bytes_since_gc:    gcs.bytes_since_gc,
          total_bytes:       gcs.total_bytes,
        }.to_json
      end
    end
  end
end
