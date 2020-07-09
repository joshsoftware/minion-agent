module Minion
  class Timer
    property interval
    property periodic

    def initialize(@interval = 1, @periodic = false, &blk)
      @canceled = false
      @block = blk
      create_timer
    end

    def create_timer
      spawn do
        loop do
          sleep @interval
          @block.call unless @canceled
          break if @canceled || !@periodic
        end
      end
    end

    def cancel
      @canceled = true
    end

    def canceled?
      @canceled
    end

    def periodic?
      @periodic
    end

    def resume
      @canceled = false
      create_timer
    end
  end
end
