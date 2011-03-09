module Charm
  module AST
    class Class
      attr_accessor :package, :name, :methods, :fields,
                    :public, :abstract, :final, :interface,
                    :source_file

      def initialize(name)
        @package = name.split('.')
        @name = @package.pop
      end

      def access_modifiers
        [@public, abstract, final].compact
      end

      def qualified_name
        (package + [name]).join '.'
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
        [@public, @private, @protected,
         static, final, volatile, transient].compact
      end
    end

    class Local < Struct.new(:index, :type)
    end

    class Code < Struct.new(:iseq, :locals)
      def local(index, type)
        locals[index] ||= Local.new.tap { |l| l.index, l.type = index, type }
      end
    end

    class LoadConstantIns < Struct.new(:ip, :mnemonic, :constant, :type)
    end

    class LoadLocalVariableIns < Struct.new(:ip, :mnemonic, :local)
    end

    class MethodInvocationIns < Struct.new(:ip, :mnemonic, :owner, :name, :type)
    end

    class FieldAccessIns < Struct.new(:ip, :mnemonic, :owner, :name, :type)
    end

    class ReturnIns < Struct.new(:ip, :mnemonic, :type)
    end

  end
end
