module Minion
  module Util
    # Given an array or a string, return a string.
    def string_from_string_or_array(val) : String
      val.is_a?(Array) ? val.as(Array).join : val.as(String)
    end

    # Let it work if the method is used as a class method.
    def self.string_from_string_or_array(val)
      val.is_a?(Array) ? val.as(Array).join : val.as(String)
    end
  end
end
