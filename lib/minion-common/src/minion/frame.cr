require "./uuid"
require "msgpack"

module Minion
  #
  # Represents a chunk of data to be transmitted, or that has been received.
  #
  # Verbs:
  # L -- log
  # C - Command
  # R - Response
  # T - Telemetry
  # Q - Query Key/Value Store
  # S - Set Key/Value

  struct Frame
    def self.from_msgpack(buffer : Slice(UInt8))
      Tuple(String, String, PayloadType).from_msgpack(buffer).as(Tuple(String, String, PayloadType))
    end

    def self.inflate(tup : Tuple(String, String, PayloadType))
      {tup[0], UUID.new(tup[1].to_s), tup[2]}
    end

    property verb
    property uuid
    property data

    @packed : Slice(UInt8)?
    @verb : String

    def initialize(verb : String | Symbol, @uuid : UUID = UUID.new, @data : PayloadType = [] of String)
      @verb = symbol_to_string(verb)
    end

    def initialize(verb : String | Symbol, @uuid : String, @data : PayloadType = [] of String)
      @uuid = UUID.new(@uuid.as(String))
      @verb = symbol_to_string(verb)
    end

    def initialize(tuple : Tuple(String, String, PayloadType))
      @verb, @uuid, @data = Frame.inflate(tuple)
    end

    def symbol_to_string(verb)
      case verb
      # The first element in the data portion of most frames should be the group ID.
      when :log
        "L"
      when :command
        "C"
      when :response
        "R"
      when :telemetry
        "T"
      when :query
        "Q"
      when :set
        "S"
      else
        verb.to_s
      end
    end

    def to_msgpack
      return @packed.not_nil! if @packed

      @packed = {@verb, @uuid.to_s, @data}.to_msgpack.not_nil!
    end
  end
end
