module Charm
  module Bytecode
    class InvalidClassFile < StandardError; end

    class Constant < Loader
      def self.load(ctx)
        idx = ctx.read :u1
        type = TYPES[idx]
        raise InvalidClassFile, "constant type #{idx}" unless type
        type.new.tap { |t| t.load ctx }
      end

      TYPES = []

      def self.tag(n)
        @tag = n
        TYPES[n] = self
      end

      class Utf8 < Constant
        tag 1
        un :bytes do |bytes, ctx|
           Bytecode.utf8(bytes)
        end
      end

      class Integer < Constant
        tag 3
        u4 :bytes
      end

      class Float < Constant
        tag 4
        u4 :bytes
      end

      class Long < Constant
        tag 5
        u4 :high_bytes
        u4 :low_bytes
      end

      class Double < Constant
        tag 6
        u4 :high_bytes
        u4 :low_bytes
      end

      class Class < Constant
        tag 7
        u2 :name_index
      end

      class String < Constant
        tag 8
        u2 :string_index
      end

      class FieldRef < Constant
        tag 9
        u2 :class_index
        u2 :name_and_type_index
      end

      class MethodRef < Constant
        tag 10
        u2 :class_index
        u2 :name_and_type_index
      end

      class InterfaceMethodRef < Constant
        tag 11
        u2 :class_index
        u2 :name_and_type_index
      end

      class NameAndType < Constant
        tag 12
        u2 :name_index
        u2 :descriptor_index
      end
    end

    class Attribute < Loader
      def self.load(ctx)
        index = ctx.read :u2
        const = ctx.constant index
        raise "No such Attribute constant #{const}" unless const
        name = const.bytes
        type = const_get(name) rescue Unknown
        length = ctx.read :u4
        type.new(length).load(ctx)
      end

      def initialize(length)
        @attribute_length = length
      end

      class Unknown < Attribute
        def load(ctx)
          @info = ctx.read @attribute_length
        end
      end

      class ConstantValue < Attribute
        u2 :constant_index
      end

      class ExceptionEntry < Loader
        u2 :start_pc
        u2 :end_pc
        u2 :handler_pc
        u2 :catch_type
      end

      class Code < Attribute
        u2 :max_stack
        u2 :max_locals
        un :code, :u4 do |code, ctx|
          Opcode::ISeq.load code.to_a
        end
        a0 :exception_table, ExceptionEntry
        a0 :attributes, Attribute
      end

      class Exceptions < Attribute
        a0 :exception_index_table, :u2
      end

      class InnerClass < Loader
        u2 :inner_class_info_index
        u2 :outer_class_info_index
        u2 :inner_name_index
        u2 :inner_class_access_flags
      end

      class InnerClasses < Attribute
        a0 :classes, InnerClass
      end

      class Synthetic < Attribute
      end

      class SourceFile < Attribute
        u2 :sourcefile_index
      end

      class LineNumberEntry < Loader
        u2 :start_pc
        u2 :line_number
      end

      class LineNumberTable < Attribute
        a0 :line_number_table, LineNumberEntry
      end

      class LocalVariableEntry < Loader
        u2 :start_pc
        u2 :length
        u2 :name_index
        u2 :descriptor_index
        u2 :index
      end

      class LocalVariableTable < Attribute
        a0 :local_variable_table, LocalVariableEntry
      end

      class Deprecated < Attribute
      end
    end

    class Field < Loader
      u2 :access_flags
      u2 :name_index
      u2 :descriptor_index
      a0 :attributes, Attribute
    end

    class Method < Loader
      u2 :access_flags
      u2 :name_index
      u2 :descriptor_index
      a0 :attributes, Attribute
    end

    class ClassFile < Loader
      u4 :magic do |magic, ctx|
        raise InvalidClassFile unless magic == 0xCAFE_BABE
        magic
      end
      u2 :minor_version
      u2 :major_version
      a1 :constant_pool, Constant
      u2 :access_flags
      u2 :this_class
      u2 :super_class
      a0 :interfaces, :u2
      a0 :fields, Field
      a0 :methods, Method
      a0 :attributes, Attribute
    end

    class Opcode

      class ISeq
        def self.load(bytes)
          iseq = new
          stream = StreamReader::FromArray.new bytes
          code_length = stream.size
          ip = 0
          while ip < code_length
            opcode = stream.read_u1
            inst = OPCODES[opcode].new(ip)
            inst.wide! if iseq.wide?
            inst.load(stream)
            ip += inst.size + 1
            iseq << inst
          end
          iseq
        end

        def initialize
          @instructions = []
        end

        attr_reader :instructions

        def <<(instruction)
          instructions << instruction
          self
        end

        def wide?
          Wide === instructions.last
        end
      end

      def load(stream)
        raise "#load Not Implemented for opcode #{mnemonic} #{type}"
      end

      module NoArgument
        def size
          0
        end
        def load(stream)
          # Nothing, this instruction takes no args.
        end
      end

      module SignedByteArgument
        def size
          1
        end

        def load(stream)
          @byte = stream.read_u1
        end
      end


      module ImplicitLocalVarArgument
        def size
          0
        end

        def load(stream)
          # Nothing, local variable is implicit.
        end
      end

      module TypeDescriptorArgument
        def size
          2
        end

        def load(stream)
          @index = stream.read_u2
        end
      end

      module FieldOrMethodInvocation
        def size
          2 # 16ubits (an index from constant pool)
        end

        def load(stream)
          @index = stream.read_u2
        end
      end

      module InvokeInterfaceOrDynamic
        def size
          3
        end
        def load(stream)
          @index = stream.read_u2
          @arg_words = stream.read_u1
        end
      end

      module LabelOffset
        def size
          2
        end
        def load(stream)
          @offset = stream.read_u2
        end
      end

      module WideLabelOffset
        include LabelOffset
        def size
          wide!
        end
      end

      module LoadConstant
        def size
          @size ||= 1
        end

        def wide!
          @size = 2
        end

        def wide?
          size > 1
        end

        def load(stream)
          @index = wide? and stream.read_u2 or stream.read_u1
        end
      end

      module LoadWideConstant
        include LoadConstant
        def size
          wide!
        end
      end


      module IntegerIncrement
        def size
          @size ||= 2
        end

        def wide!
          @size = 4
        end

        def wide?
          size > 2
        end

        def load(stream)
          @index = wide? and stream.read_u2 or stream.read_u1
          @increment = wide? and stream.read_s2 or stream.read_s1
        end
      end


      module IndexedLocalVarArgument
        def size
          @size ||= 1
        end

        def wide!
          @size = 2
        end

        def wide?
          size > 1
        end

        def load(stream)
          @index = wide? and stream.read_u2 or stream.read_u1
        end
      end

    end

  end
end
