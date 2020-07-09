module Minion
  class IoDetails
    MAX_MESSAGE_LENGTH = 65536
    property data_buffer
    property message_buffer
    property message_bytes_read
    property message_size
    property read_message_body
    property read_message_size
    property receive_size_buffer
    property send_size_buffer
    property size_read

    def initialize(
      @data_buffer = Slice(UInt8).new(MAX_MESSAGE_LENGTH),
      @message_buffer = Slice(UInt8).new(1), # TODO: This is probably better as an uninitialized?
      @message_bytes_read = 0_u16,
      @message_size = 0_u16,
      @read_message_body = false,
      @read_message_size = true,
      @receive_size_buffer = Slice(UInt8).new(2),
      @send_size_buffer = Slice(UInt8).new(2),
      @size_read = 0_u16
    )
    end
  end
end
