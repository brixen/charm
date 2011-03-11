require 'charm'
require 'ostruct'
require 'pp'
require 'yaml'

module Charm
  module Command

    def self.run(argv = ARGV.dup)
      help if argv.empty?
      cmd = Java
      if argv.first =~ /^[a-z]+$/ && const_defined?(argv.first.capitalize)
        cmd = const_get(argv.shift.capitalize)
      end rescue nil
      cmd.run(argv)
    end

    def self.help
      puts 'Usage:'
      puts '  <command> <options> <class> <argv>'
      puts ''
      puts 'All commands take the -classpath option. As expected the default'
      puts 'classpath is $PWD, or taken from the CLASSPATH environment var.'
      puts ''
      puts '<class> should be a fully qualified name. Charm supports reading'
      puts 'from jar files, but you need to have the rubyzip gem installed,'
      puts 'and rubygems loaded.'
      puts ''
      puts 'COMMANDS:'
      puts ''
      puts '   java      (default)'
      puts '             Execute the given class main method.'
      puts ''
      puts '   javax     Compile a class file to rbx bytecode'
      puts ''
      puts '   javap     Print a class file structure (inspect java opcodes)'
      puts ''
      puts '   source    Print a class file Java source (disassembly)'
      puts ''
      puts '   sexp      Print a class file as sexp (for debugging)'
      puts ''
      puts '   yaml      Print a class file as yaml (for debugging)'
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

      def self.load(argv)
        cmd = parse(argv)
        [cmd.argv.shift].map { |name|
          cmd.classpath.find_class(name) or raise "Class not found: #{name}"
        }.map { |res|
          res.open_stream { |st| Bytecode::Loader.load_stream(st, res) }
        }.tap { yield cmd if block_given? }
      end

      def self.run(argv = ARGV.dup)
        out = AST::Printer.new
        load(argv).each { |cls| cls.normalize.javap(out); out.nl! }
        puts out
      end
    end

    class Sexp
      def self.run(argv = ARGV.dup)
        Javap.load(argv).each { |cls| pp cls.sexp }
      end
    end

    class Yaml
      def self.run(argv = ARGV.dup)
        Javap.load(argv).each { |cls| puts cls.to_yaml }
      end
    end

    class Java
      def self.run(argv = ARGV.dup)
        rt = nil
        Javap.load(argv) { |cmd| rt = Runtime.new cmd.argv, cmd.classpath }.
          map { |cls| Rbx.run_class cls.normalize, rt, rt.classloader }
      end
    end

    class Javax
      def self.run(argv = ARGV.dup)
        Javap.load(argv).map { |cls| Rbx.compile_class cls.normalize }
      end
    end

  end
end
