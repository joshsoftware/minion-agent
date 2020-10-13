require "time"
require "./parse_date/format/*"

module Minion
  class ParseDate
    # This utility tries to brute force match a time/date against a hierarchy
    # of possible formats in order to be able to broadly accept, and parse a
    # wide range of date specifications.

    DEFAULT_FORMATS = [
      Time::Format::YAML_DATE,
      Time::Format::ISO_8601_DATE_TIME,
      Time::Format::ISO_8601_DATE,
      Time::Format::ISO_8601_TIME,
      Time::Format::RFC_2822,
      Time::Format::RFC_3339,
      Time::Format::HTTP_DATE,
      Minion::ParseDate::Format::UsMil,
    ]

    def self.parse(str, fallback = true) : Time?
      formats = DEFAULT_FORMATS
      return nil if str.nil?

      string = str.not_nil!
      dt : Time? = nil
      formats.each do |fmt|
        dt = if fmt.responds_to?(:parse?)
               fmt.parse?(str) rescue nil
             else
               fmt.parse(str) rescue nil
             end
        break unless dt.nil?
      end
      if dt.nil? && fallback
        new_string = string.gsub("/", "-") if string.strip.index("/").try &.> 0
        dt = parse(new_string, false)
      end
      dt
    end
  end
end
