module Charm
  module AST
    class Printer
      class LineBreak
        def initialize(level)
          @level = level
        end
        
        def to_s
          "\n" + (" " * @level * 4)
        end
      end

      def initialize(output = [], indent = 0)
        @output, @indent = output, indent
      end

      def to_s
        @output.compact.join
      end

      def <<(str)
        @output.pop if LineBreak === str && LineBreak === @output.last
        @output << str
        self
      end

      def nl!
        if block_given?
          np = self.class.new(@output, @indent + 1)
          self << np.nl
          yield np
        else
          self << nl
        end
        self
      end

      def nl
        LineBreak.new @indent
      end

    end
  end
end
