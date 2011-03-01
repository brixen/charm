module Charm
  module AST
    class Class

      def java_code(pr)
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << (interface and 'interface' or 'class') << ' '
        pr << qualified_name << ' {' << pr.nl
        pr << '}'
      end

    end
  end
end
