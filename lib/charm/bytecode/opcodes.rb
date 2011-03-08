module Charm
  module Bytecode
    class Opcode

      TYPES = %w{
           NoArgument
           SignedByteArgument
           SignedShortArgument
           IndexedLocalVarArgument
           ImplicitLocalVarArgument
           TypeDescriptorArgument
           FieldOrMethodInvocation
           InvokeInterfaceOrDynamic
           LabelOffset
           WideLabelOffset
           LoadConstant
           LoadWideConstant
           IntegerIncrement
           TableSwitch
           LookupSwitch
           MultiNewArray
           Wide
      }.map { |n| const_set(n, Module.new) }


      NEWARRAY_TYPE = {
        4  => :boolean,
        5  => :char,
        6  => :float,
        7  => :double,
        8  => :byte,
        9  => :short,
        10 => :int,
        11 => :long
      }

      OPCODES = []
      NAMED = {}

      def self.opcode(mnemonic, opcode)
        op = Class.new(Opcode) do
          define_method(:initialize) { |ip| @ip, @mnemonic, @opcode = ip, mnemonic, opcode }
        end
        OPCODES[opcode] = op
        NAMED[mnemonic] = op
      end

      attr_reader :mnemonic, :opcode

      opcode :nop, 0x00

      opcode :aconst_null, 0x01

      opcode :iconst_m1, 0x02

      opcode :iconst_0, 0x03

      opcode :iconst_1, 0x04

      opcode :iconst_2, 0x05

      opcode :iconst_3, 0x06

      opcode :iconst_4, 0x07

      opcode :iconst_5, 0x08

      opcode :lconst_0, 0x09

      opcode :lconst_1, 0x0a

      opcode :fconst_0, 0x0b

      opcode :fconst_1, 0x0c

      opcode :fconst_2, 0x0d

      opcode :dconst_0, 0x0e

      opcode :dconst_1, 0x0f

      opcode :bipush, 0x10

      opcode :sipush, 0x11

      opcode :ldc, 0x12

      opcode :ldc_w, 0x13

      opcode :ldc2_w, 0x14

      opcode :iload, 0x15

      opcode :lload, 0x16

      opcode :fload, 0x17

      opcode :dload, 0x18

      opcode :aload, 0x19

      opcode :iload_0, 0x1a

      opcode :iload_1, 0x1b

      opcode :iload_2, 0x1c

      opcode :iload_3, 0x1d

      opcode :lload_0, 0x1e

      opcode :lload_1, 0x1f

      opcode :lload_2, 0x20

      opcode :lload_3, 0x21

      opcode :fload_0, 0x22

      opcode :fload_1, 0x23

      opcode :fload_2, 0x24

      opcode :fload_3, 0x25

      opcode :dload_0, 0x26

      opcode :dload_1, 0x27

      opcode :dload_2, 0x28

      opcode :dload_3, 0x29

      opcode :aload_0, 0x2a

      opcode :aload_1, 0x2b

      opcode :aload_2, 0x2c

      opcode :aload_3, 0x2d

      opcode :iaload, 0x2e

      opcode :laload, 0x2f

      opcode :faload, 0x30

      opcode :daload, 0x31

      opcode :aaload, 0x32

      opcode :baload, 0x33

      opcode :caload, 0x34

      opcode :saload, 0x35

      opcode :istore, 0x36

      opcode :lstore, 0x37

      opcode :fstore, 0x38

      opcode :dstore, 0x39

      opcode :astore, 0x3a

      opcode :istore_0, 0x3b

      opcode :istore_1, 0x3c

      opcode :istore_2, 0x3d

      opcode :istore_3, 0x3e

      opcode :lstore_0, 0x3f

      opcode :lstore_1, 0x40

      opcode :lstore_2, 0x41

      opcode :lstore_3, 0x42

      opcode :fstore_0, 0x43

      opcode :fstore_1, 0x44

      opcode :fstore_2, 0x45

      opcode :fstore_3, 0x46

      opcode :dstore_0, 0x47

      opcode :dstore_1, 0x48

      opcode :dstore_2, 0x49

      opcode :dstore_3, 0x4a

      opcode :astore_0, 0x4b

      opcode :astore_1, 0x4c

      opcode :astore_2, 0x4d

      opcode :astore_3, 0x4e

      opcode :iastore, 0x4f

      opcode :lastore, 0x50

      opcode :fastore, 0x51

      opcode :dastore, 0x52

      opcode :aastore, 0x53

      opcode :bastore, 0x54

      opcode :castore, 0x55

      opcode :sastore, 0x56

      opcode :pop, 0x57

      opcode :pop2, 0x58

      opcode :dup, 0x59

      opcode :dup_x1, 0x5a

      opcode :dup_x2, 0x5b

      opcode :dup2, 0x5c

      opcode :dup2_x1, 0x5d

      opcode :dup2_x2, 0x5e

      opcode :swap, 0x5f

      opcode :iadd, 0x60

      opcode :ladd, 0x61

      opcode :fadd, 0x62

      opcode :dadd, 0x63

      opcode :isub, 0x64

      opcode :lsub, 0x65

      opcode :fsub, 0x66

      opcode :dsub, 0x67

      opcode :imul, 0x68

      opcode :lmul, 0x69

      opcode :fmul, 0x6a

      opcode :dmul, 0x6b

      opcode :idiv, 0x6c

      opcode :ldiv, 0x6d

      opcode :fdiv, 0x6e

      opcode :ddiv, 0x6f

      opcode :irem, 0x70

      opcode :lrem, 0x71

      opcode :frem, 0x72

      opcode :drem, 0x73

      opcode :ineg, 0x74

      opcode :lneg, 0x75

      opcode :fneg, 0x76

      opcode :dneg, 0x77

      opcode :ishl, 0x78

      opcode :lshl, 0x79

      opcode :ishr, 0x7a

      opcode :lshr, 0x7b

      opcode :iushr, 0x7c

      opcode :lushr, 0x7d

      opcode :iand, 0x7e

      opcode :land, 0x7f

      opcode :ior, 0x80

      opcode :lor, 0x81

      opcode :ixor, 0x82

      opcode :lxor, 0x83

      opcode :iinc, 0x84

      opcode :i2l, 0x85

      opcode :i2f, 0x86

      opcode :i2d, 0x87

      opcode :l2i, 0x88

      opcode :l2f, 0x89

      opcode :l2d, 0x8a

      opcode :f2i, 0x8b

      opcode :f2l, 0x8c

      opcode :f2d, 0x8d

      opcode :d2i, 0x8e

      opcode :d2l, 0x8f

      opcode :d2f, 0x90

      opcode :i2b, 0x91

      opcode :i2c, 0x92

      opcode :i2s, 0x93

      opcode :lcmp, 0x94

      opcode :fcmpl, 0x95

      opcode :fcmpg, 0x96

      opcode :dcmpl, 0x97

      opcode :dcmpg, 0x98

      opcode :ifeq, 0x99

      opcode :ifne, 0x9a

      opcode :iflt, 0x9b

      opcode :ifge, 0x9c

      opcode :ifgt, 0x9d

      opcode :ifle, 0x9e

      opcode :if_icmpeq, 0x9f

      opcode :if_icmpne, 0xa0

      opcode :if_icmplt, 0xa1

      opcode :if_icmpge, 0xa2

      opcode :if_icmpgt, 0xa3

      opcode :if_icmple, 0xa4

      opcode :if_acmpeq, 0xa5

      opcode :if_acmpne, 0xa6

      opcode :goto, 0xa7

      opcode :jsr, 0xa8

      opcode :ret, 0xa9

      opcode :tableswitch, 0xaa

      opcode :lookupswitch, 0xab

      opcode :ireturn, 0xac

      opcode :lreturn, 0xad

      opcode :freturn, 0xae

      opcode :dreturn, 0xaf

      opcode :areturn, 0xb0

      opcode :return, 0xb1

      opcode :getstatic, 0xb2

      opcode :putstatic, 0xb3

      opcode :getfield, 0xb4

      opcode :putfield, 0xb5

      opcode :invokevirtual, 0xb6

      opcode :invokespecial, 0xb7

      opcode :invokestatic, 0xb8

      opcode :invokeinterface, 0xb9

      opcode :invokedynamic, 0xba

      opcode :new, 0xbb

      opcode :newarray, 0xbc

      opcode :anewarray, 0xbd

      opcode :arraylength, 0xbe

      opcode :athrow, 0xbf

      opcode :checkcast, 0xc0

      opcode :instanceof, 0xc1

      opcode :monitorenter, 0xc2

      opcode :monitorexit, 0xc3

      opcode :wide, 0xc4

      opcode :multianewarray, 0xc5

      opcode :ifnull, 0xc6

      opcode :ifnonnull, 0xc7

      opcode :goto_w, 0xc8

      opcode :jsr_w, 0xc9

      opcode :breakpoint, 0xca

      opcode :impdep1, 0xfe

      opcode :impdep2, 0xff


      # Extend each opcode with its opcode type.
      %q(
        AAAAAAAAAAAAAAAABCKLLDDDDDEEEEEEEEEEEEEEEEEEEEAAAAAAAADD
        DDDEEEEEEEEEEEEEEEEEEEEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAIIIIIIIIIIIIIII
        IDNOAAAAAAGGGGGGGHHFBFAAFFAAQPIIJJI
      ).gsub(/\W/,'').bytes.each_with_index do |tag, opcode_index|
        type_index = tag - 65
        opcode = OPCODES[opcode_index]
        type = TYPES[type_index]
        raise "No such opcode or type" if opcode.nil? || type.nil?
        opcode.send :include, type
      end
    end
  end
end
