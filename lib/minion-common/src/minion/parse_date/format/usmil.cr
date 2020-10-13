module Minion
  class ParseDate
    module Format
      class UsMil
        # TODO: Add proper time zone support.
        FORMATS = [
          "%d %b %Y",
          "%d %B %Y",
          "%d%b%Y",
          "%d%B%Y",
          "%d %H%M %b %Y",
          "%d %H%M %B %Y",
          "%d%H%M%b%Y",
          "%d%H%M%B%Y",
          "%d %H%M%S %b %Y",
          "%d %H%M%S %B %Y",
          "%d%H%M%S%b%Y",
          "%d%H%M%S%B%Y",
        ]

        def self.parse(string, location : Time::Location? = Time::Location::UTC) : Time?
          dt : Time? = nil
          FORMATS.each do |format|
            dt = Time::Format.new(format, location).parse(string) rescue nil
            break unless dt.nil?
          end

          dt
        end
      end
    end
  end
end
