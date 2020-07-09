module Minion
  module Util
    # Given an array or a string, return a string.
    def self.string_from_string_or_array(val) : String
      val.is_a?(Array) ? val.as(Array).join : val.as(String)
    end
  end
end
