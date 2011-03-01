module Charm
  module AST
    class Class
      attr_accessor :package, :name, :methods, :fields,
                    :public, :abstract, :final, :interface

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
      attr_accessor :name,
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

  end
end
