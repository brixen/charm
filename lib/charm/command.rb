require 'charm/bytecode/loader'
require 'charm/bytecode/class_file'
require 'charm/bytecode/normalize'
require 'charm/ast'
require 'charm/ast/printer'
require 'charm/ast/java_code'
require 'charm/classpath'
require 'ostruct'

module Charm
  module Command

    def self.run(argv = ARGV.dup)
      help if argv.empty?
      cmd = Java
      if const_defined?(argv.first.capitalize)
        cmd = const_get(argv.shift.capitalize)
      end
      cmd.run(argv)
    end

    def self.help
      puts 'Usage:'
      puts '  <command> <options> <argv>'
      puts ''
      puts 'COMMANDS:'
      puts ''
      puts '   java      (default)'
      puts '             Execute the given class main method.'
      puts ''
      puts '   javap     Print a class file structure'
      exit 0
    end

    class Javap
      def self.parse(argv)
        cmd = OpenStruct.new
        cmd.classpath = Classpath.new File.expand_path(".")
        cmd.argv = []
        until argv.empty?
          case argv.first
          when "-classpath"
            argv.shift
            cmd.classpath = Classpath.new *argv.shift.
              split(File::PATH_SEPARATOR).map { |s| File.expand_path(s) }
          else
            cmd.argv << argv.shift
          end
        end
        cmd
      end

      def self.run(argv = ARGV.dup)
        cmd = parse(argv)
        cmd.argv.map { |name|
          cmd.classpath.find_class(name) or raise "Class not found: #{name}"
        }.map { |res|
          res.open_stream { |st| Bytecode::Loader.load_stream(st).normalize }
        }.each { |cls| cls.java_code(AST::Printer.new(STDOUT)); puts }
      end
    end

    class Java
    end

  end
end
