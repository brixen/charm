module Charm
  module Bytecode
    class Loader

      class Context
        attr_reader :reader, :class_file
        
        def initialize(reader, class_file)
          @reader, @class_file = reader, class_file
        end

        def read(type)
          return @reader.read(type) if Fixnum === type
          return @reader.send("read_#{type}") if
            Symbol === type && @reader.respond_to?("read_#{type}")
          type.load self
        end

        def constant(index)
          class_file.constant_pool[index]
        end
      end

      def self.load_stream(stream)
        ctx = Context.new StreamReader.new(stream), ClassFile.new
        ctx.class_file.load ctx
      end

      def self.load(context)
        new.tap { |n| n.load context }
      end

      def self.inherited(obj)
        obj.extend ClassMethods
      end

      def load(context)
        self.class.readers.each { |block| block[context, self] }
        self
      end

      module ClassMethods
        def readers
          @readers ||= []
        end

        def un(name, len_type = :u2, &action)
          attr_reader name
          readers.push lambda { |context, object|
            len = context.read len_type
            value = context.read len
            object.instance_variable_set("@"+name.to_s, value)
            action[value, context] if action
            value
          }
        end

        def u0(name, type, &action)
          attr_reader name
          readers.push lambda { |context, object|
            value = context.read type
            object.instance_variable_set("@"+name.to_s, value)
            action[value, context] if action
            value
          }
        end

        def u1(name, &action)
          u0 name, :u1, &action
        end

        def u2(name, &action)
          u0 name, :u2, &action
        end

        def u3(name, &action)
          u0 name, :u3, &action
        end

        def u4(name, &action)
          u0 name, :u4, &action
        end

        def a0(name, type, len_type = :u2, &action)
          ao(0, name, type, len_type, &action) 
        end

        def a1(name, type, len_type = :u2, &action)
          ao(1, name, type, len_type, &action)
        end

        def ao(offset, name, type, len_type, &action)
          attr_reader name
          readers.push lambda { |context, object|
            value = []
            object.instance_variable_set("@"+name.to_s, value)
            count = context.read len_type
            (count - offset).times do |index|
              value[index + offset] = context.read type
            end
            action[value, context] if action
            value
          }
        end

      end

    end

    class StreamReader
      def initialize(stream)
        @stream = stream
      end

      def read(n = 1)
        @stream.read n
      end

      # read 8 bits
      def read_u1
        read.bytes.first & 0xff
      end

      # read 16 bits
      def read_u2
        (read_u1 << 8) | read_u1
      end

      # read 32 bits
      def read_u3
        (read_u1 << 16) | read_u2
      end

      # read 64 bits
      def read_u4
        (read_u1 << 24) | read_u3
      end
    end

  end
end
