module Charm
  module AST
    class Class

      def java_code(pr)
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << (interface and 'interface' or 'class') << ' '
        pr << qualified_name << ' {'
        pr.nl! { |np|
          methods.map { |m| m.java_code(np.nl!); np.nl! }
        } unless methods.empty?
        pr << pr.nl << '}'
      end

    end

    class Method
      def java_code(pr)
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << return_type.signature << ' ' if return_type
        pr << name
        pr << '('
        pr << parameter_types.map { |p| p.signature }.join(', ')
        pr << ')'
        if abstract
          pr << ';'
        else
          pr << ' {'
          pr.nl! << '}'
        end
        pr.nl
      end
    end
  end
end
