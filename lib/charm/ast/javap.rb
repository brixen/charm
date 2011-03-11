module Charm
  module AST
    class Type
      attr_reader :dimension, :parameters, :package, :simple_name

      def initialize(name, dimension = nil)
        @dimension = dimension || 0
        @parameters = []
        if Symbol === name
          @name = name
        else
          parts = name.split('.')
          @package = parts[0...-1]
          @parent = parts.last.split('$')
          @simple_name = @parent.pop
        end
      end

      def name
        @name || [@package, [@parent, @simple_name].flatten.join('$')].flatten.join('.')
      end

      def primitive?
        Symbol === name
      end

      def ary?
        dimension > 0
      end

      def signature
        name.to_s + ("[]" * dimension)
      end
    end

    class Class

      def javap(pr)
        pr << 'package ' << type.package << ';' << pr.nl unless type.package
        pr << '/** Compiled from ' << source_file << ' **/' << pr.nl
        pr << access_modifiers.join(' ') << ' ' unless
          access_modifiers.empty?
        pr << (interface and 'interface' or 'class') << ' '
        pr << type.simple_name << ' {'
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
          pr.nl! { |np| code.iseq.each { |ins| ins.javap(np); np.nl! }}
          pr.nl! << '}'
        end
        pr.nl
      end
    end

    module JavapIpOpcode
      def ip_opcode
        '#%-4i %-18s' % [ip, mnemonic]
      end

      def javap(pr)
          pr << ip_opcode
      end
    end

    class LoadLocalVariableIns
      include JavapIpOpcode
    end

    class FieldAccessIns
      include JavapIpOpcode
      def javap(pr)
          pr << ip_opcode << owner << '.' << name << ':' << type.signature
      end
    end

    class MethodInvocationIns
      include JavapIpOpcode
      def javap(pr)
          pr << ip_opcode
          pr << owner << '.' << name << '('
          pr << type[1..-1].map { |t| t.signature }.join(', ')
          pr << '):' << type.first.signature
      end
    end

    class LoadConstantIns
      include JavapIpOpcode
      def javap(pr)
          pr << ip_opcode
          pr << type.signature << ' ' << constant.inspect
      end
    end

    class ReturnIns
      include JavapIpOpcode
    end

    class IncrementLocalIns
      include JavapIpOpcode
    end

    class StoreLocalVariableIns
      include JavapIpOpcode
    end

    class LoadArrayItemIns
      include JavapIpOpcode
    end

    class StoreArrayItemIns
      include JavapIpOpcode
    end

    class DupIns
      include JavapIpOpcode
    end

    class InterfaceInvocationIns
      include JavapIpOpcode
    end

    class NewIns
      include JavapIpOpcode
    end

    class JumpIns
      include JavapIpOpcode

      def javap(pr)
          pr << ip_opcode << '#' << (ip + offset)
      end
    end

    class PopIns
      include JavapIpOpcode
    end

    class NoopIns
      include JavapIpOpcode
    end

  end
end
