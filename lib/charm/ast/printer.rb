module Charm
  module AST
    class Printer
      def initialize(output = "", indent = 0)
        @output, @indent = output, indent
      end

      def <<(str)
        @output << str
        self
      end

      def nl!
        if block_given?
          np = self.class.new(@output, @indent + 1)
          @output << np.nl
          yield np
        else
          @output << nl
        end
        self
      end

      def nl
        "\n" << indent
      end

      def indent
        ' ' * (@indent * 4)
      end
    end
  end
end
