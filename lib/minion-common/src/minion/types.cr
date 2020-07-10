module Minion
  alias PayloadType = Array(Array(String) | String) | Array(String)
  alias FullOrPackedFrame = Tuple(String | Symbol, UUID | String, PayloadType) | Slice(UInt8)
  alias ReceivedFrame = Tuple(String, String, PayloadType)
end
