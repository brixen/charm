module Charm
  module Rbx
    class StaticScope < Rubinius::StaticScope
      def const_get(name)
        scope = self
        while scope and scope.module != Object
          return scope.const_get(name) if scope.module.const_defined?(name)
          scope = scope.parent
        end

        return scope.const_get(name) if Object.const_defined?(name)
      end
    end

    def self.run_class(cls, rt, cl)
      name = cls.type.name.to_sym

      cm = compile_class(cls)
      scope = StaticScope.new(cl.namespace,
                StaticScope.new(rt.namespace,
                  StaticScope.new(Runtime)))

      script =  Rubinius::CompiledMethod::Script.new(cm)
      scope.script = script
      cm.scope = scope

      target = cl.namespace
      target.metaclass.method_table.store name, cm, :private

      java_class = target.send name
      # todo invoke static main method with rt.argv
    end

    def self.compile_class(cls)
      cm = generator cls  do |g|
        g.push_scope
        g.push_literal cls.type.name.to_sym
        g.push_nil
        g.send :const_set, 2
        g.ret
      end
      printer = Rubinius::Compiler::MethodPrinter.new
      printer.bytecode = true
      printer.assembly = true
      printer.print_method cm
      cm
    end

    def self.generator(cls)
      g = Rubinius::Generator.new
      g.name = cls.resource.to_s.to_sym
      g.file = cls.source_file.to_sym
      g.set_line 0

      g.push_state Rubinius::AST::ClosedScope.new(0)

      yield g

      g.close
      g.use_detected
      g.encode

      g.package Rubinius::CompiledMethod
    end
  end
end
