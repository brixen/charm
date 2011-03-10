module Charm
  module Bytecode
    class ClassFile
      def normalize
        AST::Class.new(qualified_name).tap do |cls|
          [:public, :abstract, :final, :interface].
           each { |am| cls.send("#{am}=", am) if send("#{am}?") }
          cls.fields = fields.map { |m| m.normalize(self) }
          cls.methods = methods.map { |m| m.normalize(self) }
          cls.source_file = utf8(source_file)
        end
      end

      def qualified_name
        utf8(self[this_class].name_index).gsub('/', '.')
      end

      def name
        qualified_name.split('.').last
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

      def source_file
        attributes.find { |s| Attribute::SourceFile === s }.
          sourcefile_index
      end
    end

    class Type < Struct.new(:name, :dimension)
      def self.from_method_desc(desc)
        m = /\((.*)\)(.*)/.match desc
        types = [m[2]] + m[1].scan(/(\[*L[^;]+;|\[*[BCDFIJSVZ])/)
        types.flatten.compact.map { |a| from_desc a }
      end

      def self.from_desc(desc)
        dimension = 0
        desc = desc.sub(/^\[+/) { |s| dimension = s.length; '' }
        type = case desc
          when /^B/ then :byte
          when /^C/ then :char
          when /^D/ then :double
          when /^F/ then :float
          when /^I/ then :int
          when /^J/ then :long
          when /^S/ then :short
          when /^V/ then :void
          when /^Z/ then :boolean
          when /^L/ then desc[1...-1].gsub('/', '.')
          when /\// then desc.gsub('/', '.')
          else raise "Invalid type descriptor #{desc}"
        end
        new type, dimension
      end

      def self.from_code(code)
        type = case code.to_s[0,1]
               when 'a' then 'Ljava.lang.Object;'
               when 'i' then :int
               when 'l' then :long
               when 'd' then :double
               when 'b' then :byte
               when 'c' then :char
               else raise "Invalid type descriptor: #{code}"
               end
        new type, 0
      end

      def signature
        name.to_s + ("[]" * dimension)
      end
    end

    class Field
      def normalize(cf)
        AST::Field.new.tap do |f|
          desc = cf.utf8(descriptor_index)
          f.type = Type.from_desc(desc)
          f.name = cf.utf8(name_index)
          [:public, :private, :protected,
           :static, :final, :volatile, :transient ].
           each { |am| f.send("#{am}=", am) if send("#{am}?") }
        end
      end

      def public?
        (@access_flags & 0x0001) == 0x0001
      end

      def private?
        (@access_flags & 0x0002) == 0x0002
      end

      def protected?
        (@access_flags & 0x0004) == 0x0004
      end

      def static?
        (@access_flags & 0x0008) == 0x0008
      end

      def final?
        (@access_flags & 0x0010) == 0x0010
      end

      def volatile?
        (@access_flags & 0x0040) == 0x0040
      end

      def transient?
        (@access_flags & 0x0080) == 0x0080
      end
    end

    class Method
      def normalize(cf)
        AST::Method.new.tap do |m|
          m.name = cf.utf8(name_index)
          [:public, :private, :protected, :native, :strict,
           :static, :abstract, :final, :synchronized ].
           each { |am| m.send("#{am}=", am) if send("#{am}?") }
          types = Type.from_method_desc cf.utf8(descriptor_index)
          m.return_type = types.shift
          m.return_type = nil if m.name == "<init>" || m.name == "<clinit>"
          m.parameter_types = types
          m.name = cf.name if m.name == "<init>"
          m.name = nil if m.name == "<clinit>"
          m.code = attributes.find { |a| Attribute::Code === a }.iseq.normalize(cf)
        end
      end

      def public?
        (@access_flags & 0x0001) == 0x0001
      end

      def private?
        (@access_flags & 0x0002) == 0x0002
      end

      def protected?
        (@access_flags & 0x0004) == 0x0004
      end

      def static?
        (@access_flags & 0x0008) == 0x0008
      end

      def final?
        (@access_flags & 0x0010) == 0x0010
      end

      def synchronized?
        (@access_flags & 0x0020) == 0x0020
      end

      def native?
        (@access_flags & 0x0100) == 0x0100
      end

      def abstract?
        (@access_flags & 0x0400) == 0x0400
      end

      def strict?
        (@access_flags & 0x0800) == 0x0800
      end

    end

    class Opcode
      class ISeq
        def normalize(cf)
          AST::Code.new.tap do |code|
            code.locals = []
            code.iseq = instructions.map { |i|
              begin
                i.normalize(cf, code)
              rescue NoMethodError
                raise "Not implemented normalize #{i.mnemonic} #{i.class.ancestors.inspect}"
              end
            }
          end
        end
      end

      module ImplicitLocalVarArgument
        def normalize(cf, code)
          case @mnemonic.to_s
          when /(\w)(load|store)_(\d)/ then
            type, oper, idx = Type.from_code($1), $2, $3.to_i
            cls = AST.const_get("#{oper.capitalize}LocalVariableIns")
            cls.new @ip, @mnemonic, code.local(idx, type)
          else raise "Normalize not implemented #{@mnemonic} #{self.class.ancestors.inspect}"
          end
        end
      end

      module FieldOrMethodInvocation
        def normalize(cf, code)
          ivk = @mnemonic.to_s =~ /invoke/
          ref = cf[@index]
          clazz = cf[ref.class_index]
          name_and_type = cf[ref.name_and_type_index]
          class_name = cf[clazz.name_index].bytes.gsub('/', '.')
          member_name = cf[name_and_type.name_index].bytes
          member_desc = cf[name_and_type.descriptor_index].bytes
          member_cls = AST.const_get(ivk && :MethodInvocationIns || :FieldAccessIns)
          member = member_cls.new(@ip, @mnemonic)
          member.owner = class_name
          member.name = member_name
          member.type = Type.send(ivk && :from_method_desc || :from_desc, member_desc)
          member
        end
      end

      module NoArgument
        def normalize(cf, code)
          case @mnemonic.to_s
          when 'return' then AST::ReturnIns.new @ip, @mnemonic, Type.from_desc('V')
          when 'dup' then AST::DupIns.new @ip, @mnemonic
          when 'pop' then AST::PopIns.new @ip, @mnemonic
          when 'pop2' then AST::PopIns.new @ip, @mnemonic, :wide
          when 'nop' then AST::NoopIns.new @ip, @mnemonic
          when /(\w)const_(\d)/ then
            AST::LoadConstantIns.new @ip, @mnemonic, $2.to_i, Type.from_code($1)
          when /(\w)a(load|store)/ then
            type, oper = Type.from_code($1), $2
            AST::const_get("#{oper.capitalize}ArrayItemIns").new @ip, @mnemonic, type
          else raise "Normalize not implemented #{@mnemonic} #{self.class.ancestors.inspect}"
          end
        rescue => e
          puts e
          raise e
        end
      end

      module LoadConstant
        def normalize(cf, code)
          target = cf[@index]
          case target
          when Constant::String
            type = Type.from_desc "Ljava.lang.String;"
            const = cf[target.string_index].bytes
            AST::LoadConstantIns.new @ip, @mnemonic, const, type
          else raise "Unknown type of constant #{@mnemonic} #{target}"
          end
        end
      end

      module TypeDescriptorArgument
        def normalize(cf, code)
          type =  Type.from_desc cf[cf[@index].name_index].bytes
          case @mnemonic.to_s
          when 'new' then AST::NewIns.new @ip, @mnemonic, type
          else raise "normalize not implemented #{@mnemonic}"
          end
        end
      end

      module LabelOffset
        def normalize(cf, code)
          case @mnemonic.to_s
          when /if_(\w)cmp(\w+)/ then
            type, oper = Type.from_code($1), $2.to_sym
            AST::JumpIns.new @ip, @mnemonic, @offset, oper, type
          when 'goto' then
            AST::JumpIns.new @ip, @mnemonic, @offset
          else raise "Normalize not implemented #{@mnemonic} #{self.class.ancestors.inspect}"
          end
        end
      end

      module InvokeInterfaceOrDynamic
        def normalize(cf, code)
          ref = cf[@index]
          clazz = cf[ref.class_index]
          name_and_type = cf[ref.name_and_type_index]
          class_name = cf[clazz.name_index].bytes.gsub('/', '.')
          member_name = cf[name_and_type.name_index].bytes
          member_desc = cf[name_and_type.descriptor_index].bytes
          member_type = Type.from_method_desc member_desc
          AST::InterfaceInvocationIns.new @ip, @mnemonic, class_name,
            member_name, member_type, @arg_words
        end
      end

      module IntegerIncrement
        def normalize(cf, code)
          AST::IncrementLocalIns.new @ip, @mnemonic, code.local(@index), @increment
        end
      end

    end

  end
end
