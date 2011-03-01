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
        un :bytes
      end

      class Integer < Constant
        tag 3
        u4 :bytes
      end

      class Float < Constant
        tag 3
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
        un :code, :u4
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
  end
end
