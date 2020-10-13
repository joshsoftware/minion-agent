module Minion
  class Timer
    property interval
    property periodic

    def initialize(@interval : Int32 | Float32 = 1, @periodic = false, &blk : Minion::Timer ->)
      @canceled = false
      @block = blk
      create_timer
    end

    def create_timer
      spawn do
        loop do
          sleep @interval
          @block.call(self) unless @canceled
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
