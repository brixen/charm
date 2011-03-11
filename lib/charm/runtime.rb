module Charm
  class Runtime

    class Namespace < ::Module
      def normalize_const_name(name)
        ::Type.coerce_to_symbol(name)
      end
    end

    attr_reader :classloader

    def initialize(argv = [], classpath = Classpath.new)
      @argv = argv
      @classloader = ClassLoader.new classpath
    end

    def namespace
      @namespace ||= Namespace.new
    end

    class ClassLoader
      def initialize(classpath)
        @classpath = classpath
      end

      def namespace
        @namespace ||= Namespace.new
      end
    end

  end
end
