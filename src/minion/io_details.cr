module Minion
  class IoDetails
    property read_message_size
    property message_bytes_read
    property size_read
    property send_size_buffer
    property read_message_body
    property read_message_size
    property message_size
    property data_buffer
    property message_buffer
    property receive_size_buffer

    def initialize(
      @read_message_size = true,
      @message_bytes_read = 0_u16,
      @size_read = 0_u16,
      @send_size_buffer = Slice(UInt8).new(2),
      @read_message_body = false,
      @message_size = 0_u16,
      @data_buffer = Slice(UInt8).new(Client::MAX_MESSAGE_LENGTH),
      @message_buffer = Slice(UInt8).new(1), # Placeholder
      @receive_size_buffer = Slice(UInt8).new(2)
    )
      super()
    end
  end
end
