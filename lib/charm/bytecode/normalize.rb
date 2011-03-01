module Charm
  module Bytecode
    class ClassFile
      def normalize
        AST::Class.new.tap do |cls|
          name =  self[self[this_class].name_index].bytes.split('.')
          cls.name = name.pop
          cls.package = name
          cls.interface = interface?
          cls.public = public?
          cls.abstract = abstract?
          cls.final = final?
        end
      end

      def [](idx)
        constant_pool[idx]
      end

      def utf8(index)
        self[index].bytes
      end

      def public?
        (@access_flags & 0x0001) == 0x0001
      end

      def final?
        (@access_flags & 0x0010) == 0x0010
      end

      def super?
        (@access_flags & 0x0020) == 0x0020
      end

      def interface?
        (@access_flags & 0x0200) == 0x0200
      end

      def abstract?
        (@access_flags & 0x0400) == 0x0200
      end

      def class?
        !interface?
      end


    end
  end
end
