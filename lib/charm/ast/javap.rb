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
          pr.nl! { |np| iseq.instructions.each { |ins| ins.javap(np); np.nl! }}
          pr.nl! << '}'
        end
        pr.nl
      end
    end

    class Bytecode::Opcode
      module ImplicitLocalVarArgument
        def javap(pr)
          pr << '#' << @ip << ' ' << @mnemonic.to_s
        end
      end

      module FieldOrMethodInvocation
        def javap(pr)
          pr << '#' << @ip << ' ' << @mnemonic.to_s << ' // '
          pr << @class_name << '.' << @member_name
          if @mnemonic.to_s =~ /invoke/
            pr << '('
            pr << @member_type[1..-1].map(&:signature).join(', ')
            pr << '):' << @member_type.first.signature
          else
            pr << ':' << @member_type.signature
          end
        end
      end

      module LoadConstant
        def javap(pr)
        end
      end

      module NoArgument
        def javap(pr)
        end
      end
    end
  end
end
