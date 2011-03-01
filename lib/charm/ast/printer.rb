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
        @output << nl << indent
        yield self.class.new(@buffer, @indent + 1) if block_given?
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
