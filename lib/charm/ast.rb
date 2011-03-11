module Charm
  module AST
    class Class
      attr_accessor :type, :methods, :fields,
                    :public, :abstract, :final, :interface,
                    :source_file, :resource

      def access_modifiers
        [@public, abstract, final].compact
      end
    end

    class Method
      attr_accessor :name, :code,
                    :return_type, :parameter_types,
                    :public, :private, :protected,
                    :abstract, :final, :static,
                    :synchronized, :native, :strict

      def access_modifiers
        [@public, @private, @protected,
         abstract, final, static,
         synchronized, native, strict].compact
      end
    end

    class Field
      attr_accessor :name, :type,
                    :public, :private, :protected,
                    :static, :final,
                    :volatile, :transient

      def access_modifiers
        [@public, @private, @protected, static, final, volatile, transient].compact
      end
    end

    class Local < Struct.new(:index, :type)
    end

    class Code < Struct.new(:iseq, :locals)
      def local(index, type = nil)
        locals[index] ||= Local.new index, type
      end
    end

    class LoadConstantIns < Struct.new(:ip, :mnemonic, :constant, :type)
    end

    class IncrementLocalIns < Struct.new(:ip, :mnemonic, :local, :increment)
    end

    class LoadLocalVariableIns < Struct.new(:ip, :mnemonic, :local)
    end

    class StoreLocalVariableIns < Struct.new(:ip, :mnemonic, :local)
    end

    class LoadArrayItemIns < Struct.new(:ip, :mnemonic, :type)
    end

    class StoreArrayItemIns < Struct.new(:ip, :mnemonic, :type)
    end

    class MethodInvocationIns < Struct.new(:ip, :mnemonic, :owner, :name, :type)
    end

    class InterfaceInvocationIns < Struct.new(:ip, :mnemonic, :owner, :name, :type, :args)
    end

    class FieldAccessIns < Struct.new(:ip, :mnemonic, :owner, :name, :type)
    end

    class ReturnIns < Struct.new(:ip, :mnemonic, :type)
    end

    class DupIns < Struct.new(:ip, :mnemonic)
    end

    class NewIns < Struct.new(:ip, :mnemonic, :type)
    end

    class JumpIns < Struct.new(:ip, :mnemonic, :offset, :condition, :type)
    end

    class PopIns < Struct.new(:ip, :mnemonic, :wide)
    end

    class NoopIns < Struct.new(:ip, :mnemonic)
    end

  end
end
