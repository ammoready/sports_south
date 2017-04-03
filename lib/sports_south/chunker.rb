module SportsSouth
  class Chunker

    attr_accessor :chunk, :total_count, :current_count, :size

    def initialize(size, total_count = nil)
      @size           = size
      @chunk          = Array.new
      @current_count  = 0
      @total_count    = total_count
    end

    def add(row)
      reset if is_full?

      @chunk.push(row)

      @current_count += 1
    end

    def reset
      @chunk.clear
    end

    def is_full?
      @chunk.count == @size
    end

    def is_complete?
      @total_count == @current_count
    end

  end
end
