module Charm
  module AST
    class Class

      def javap(pr)
        pr << 'package ' << package.join('.') << ';' << pr.nl unless 
           package.empty?
        pr << '/** Compiled from ' << source_file << ' **/' << pr.nl
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << (interface and 'interface' or 'class') << ' '
        pr << name << ' {'
        pr.nl! { |np|
          fields.map { |m| m.javap(np.nl!); np.nl! }
        } unless fields.nil? || fields.empty?
        pr.nl! { |np|
          methods.map { |m| m.javap(np.nl!); np.nl! }
        } unless methods.nil? || methods.empty?
        pr << pr.nl << '}'
      end

    end

    class Field
      def javap(pr)
        pr << access_modifiers.join(' ') << ' ' unless 
          access_modifiers.empty?
        pr << type.signature << ' ' << name << ';'
      end
    end

    class Method
      def javap(pr)
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << return_type.signature << ' ' if return_type
        pr << name
        pr << '(' if name
        pr << parameter_types.map { |p| p.signature }.join(', ')
        pr << ')' if name
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
