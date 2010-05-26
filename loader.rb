$KCODE = 'u'

class JavaLoader
  attr_reader :name

  def initialize(name)
    @name = name
    @stream = File.open name, "rb"
    @reader = StreamReader.new @stream
  end

  def load
    magic
    minor_version
    major_version
    constant_pool_count
    constant_pool_array
    access_flags
    this_class
    super_class
    interfaces_count
    interfaces_array
    fields_count
    fields_array
    methods_count
    methods_array
    attributes_count
    attributes_array
  end

  def magic
    @magic = @reader.read_int
    unless @magic == JavaClassMagic
      raise InvalidJavaClassFile, "unexpected magic value: 0x#{@magic.to_s 16}"
    end
  end

  def minor_version
    @minor_version = @reader.read_short
  end

  def major_version
    @major_version = @reader.read_short
  end

  def constant_pool_count
    @constant_pool_count = @reader.read_short
  end

  def constant_pool_array
    @constant_pool = Constant.load @constant_pool_count, @reader
  end

  def access_flags
    @access_flags = @reader.read_short
  end

  def this_class
    @this_class = @reader.read_short
  end

  def super_class
    @super_class = @reader.read_short
  end

  def interfaces_count
    @interfaces_count = @reader.read_short
  end

  def interfaces_array
    @interfaces = []
    @interfaces_count.times { @interfaces << @reader.read_short }
  end

  def fields_count
    @fields_count = @reader.read_short
  end

  def fields_array
    @fields = []
    @fields_count.times { @fields << Field.new(@reader).load }
  end

  def methods_count
    @methods_count = @reader.read_short
  end

  def methods_array
    @methods = []
    @methods_count.times { @methods << Method.new(@reader).load }
  end

  def attributes_count
    @attributes_count = @reader.read_short
  end

  def attributes_array
    @attributes = Attribute.load @attributes_count, @reader
  end

  def inspect_array(name, items, count)
    s = "  #{name}[#{count}]:\n"
    items.each_with_index do |x, i|
      s << "    #{'%2d' % (i+1)}. #{x.inspect}\n"
    end
    s
  end

  def inspect
    s = <<-EOI
  #{@name}
  #{"-" * @name.size}
  Major version: #{@major_version}
  Minor version: #{@minor_version}
  Constants[#{@constant_pool_count-1}]:
    EOI
    s << inspect_array("Contants", @constant_pool[1..-1], @constant_pool_count-1)
    s << inspect_array("Fields", @fields, @fields_count)
    s << inspect_array("Methods", @methods, @methods_count)
    s << inspect_array("Attributes", @attributes, @attributes_count)
    s
  end

  JavaClassMagic = 0xcafebabe

  class InvalidJavaClassFile < Exception; end

  class StreamReader
    def initialize(stream)
      @stream = stream
    end

    def read(n)
      @stream.read n
    end

    def read_utf8(n)
      # TODO: decode modified utf-8
      @stream.read n
    end

    def read_byte
      @stream.readchar
    end

    def read_short
      (@stream.readchar << 8) | @stream.readchar
    end

    def read_int
      (read_short << 16) | read_short
    end

    def read_long
      (read_int << 32) | read_int
    end
  end

  class Constant
    def self.load(count, reader)
      c = []
      skip = false

      (1...count).each do |i|
        if skip
          skip = false
          next
        end

        case type = reader.read_byte
        when 1
          c[i] = Utf8.new reader
        when 3
          c[i] = Integer.new reader
        when 4
          c[i] = Float.new reader
        when 5
          c[i] = Long.new reader
          skip = true
        when 6
          c[i] = Double.new reader
          skip = true
        when 7
          c[i] = Class.new reader
        when 8
          c[i] = String.new reader
        when 9
          c[i] = Field.new reader
        when 10
          c[i] = Method.new reader
        when 11
          c[i] = InterfaceMethod.new reader
        when 12
          c[i] = NameAndType.new reader
        else
          raise InvalidJavaConstant, "unknown constant: #{type}"
        end
      end

      return c
    end

    def initialize(reader)
      @reader = reader
      self.load
    end

    def short_name
      "#{self.class.name.split("::").last}:".ljust(15)
    end

    class Class < Constant
      def load
        @name_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@name_index}"
      end
    end

    class Field < Constant
      def load
        @class_index = @reader.read_short
        @name_and_type_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@class_index}, \##{@name_and_type_index}"
      end
    end

    class Method < Constant
      def load
        @class_index = @reader.read_short
        @name_and_type_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@class_index}, \##{@name_and_type_index}"
      end
    end

    class InterfaceMethod < Constant
      def load
        @class_index = @reader.read_short
        @name_and_type_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@class_index}, \##{@name_and_type_index}"
      end
    end

    class String < Constant
      def load
        @string_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@string_index}"
      end
    end

    class Integer < Constant
      def load
        @value = @reader.read_int
      end

      def inspect
        "#{short_name} #{@value}"
      end
    end

    class Float < Constant
      def load
        # TODO: make this @value
        @bytes = @reader.read_int
      end

      def inspect
        "#{short_name} #{@bytes}"
      end
    end

    class Long < Constant
      def load
        @value = @reader.read_long
      end

      def inspect
        "#{short_name} #{@value}"
      end
    end

    class Double < Constant
      def load
        # TODO: make this @value
        @bytes = @reader.read_long
      end

      def inspect
        "#{short_name} #{@bytes}"
      end
    end

    class NameAndType < Constant
      def load
        @name_index = @reader.read_short
        @descriptor_index = @reader.read_short
      end

      def inspect
        "#{short_name} \##{@name_index}, \##{@descriptor_index}"
      end
    end

    class Utf8 < Constant
      def load
        @length = @reader.read_short
        @bytes = @reader.read_utf8 @length
      end

      def inspect
        "#{short_name} #{@bytes.inspect}"
      end
    end
  end

  class Attribute
    class ConstantValue < Attribute
      def load
        @attribute_name_index = @reader.read_short
        @attribute_length = @reader.read_int
        @constantvalue_index = @reader.read_short
      end
    end

    class Unknown < Attribute
      def load
        @attribute_name_index = @reader.read_short
        @attribute_length = @reader.read_int
        @attributes = @reader.read @attribute_length
      end
    end

    def self.load(count, reader)
      attributes = []
      count.times do
        a = Unknown.new reader
        a.load
        attributes << a
      end
      attributes
    end

    def initialize(reader)
      @reader = reader
    end

    def inspect
      "\##{@attribute_name_index}"
    end
  end

  class Field
    def initialize(reader)
      @reader = reader
    end

    def load
      @access_flags = @reader.read_short
      @name_index = @reader.read_short
      @descriptor_index = @reader.read_short
      @attributes_count = @reader.read_short
      @attributes = Attribute.load @attributes_count, @reader

      self
    end

    def inspect
      "name: \##{@name_index}, descriptor: \##{@descriptor_index}"
    end
  end

  class Method
    def initialize(reader)
      @reader = reader
    end

    def load
      @access_flags = @reader.read_short
      @name_index = @reader.read_short
      @descriptor_index = @reader.read_short
      @attributes_count = @reader.read_short
      @attributes = Attribute.load @attributes_count, @reader

      self
    end

    def inspect
      "name: \##{@name_index}, descriptor: \##{@descriptor_index}"
    end
  end
end
