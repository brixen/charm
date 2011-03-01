module Charm
  module AST
    class Class

      attr_accessor :package, :name, :methods, :fields
      attr_accessor :public, :abstract, :final, :interface

      def access_modifiers
        mods = []
        mods << :public if @public
        mods << :abstract if @abstract
        mods << :final if @final
        mods
      end

      def qualified_name
        (package + [name]).join '.'
      end

    end
  end
end
