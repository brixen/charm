module Charm
  class Classpath
    def initialize(*paths)
      @paths = paths
      @cached = Hash.new
    end

    def find_class(class_name)
      resource_name = class_name.gsub('.', '/') + ".class"
      find_resource(resource_name)
    end

    def find_resource(resource_name)
      @paths.find do |path|
        if /\.(jar|zip)$/i === path && File.exists?(path)
          require 'zip/zip'
          if Zip::ZipFile.new(path).find_entry(resource_name)
            @cached[resource_name] = "jar:file://"+path+"!/"+resource_name
          end
        elsif File.directory?(path)
          file = File.expand_path(resource_name, path)
          @cached[resource_name] = "file://"+file if File.exist?(file)
        end
      end unless @cached[resource_name]
      @cached[resource_name] && Resource.new(@cached[resource_name])
    end

    class Resource
      def initialize(location)
        @location = location
      end

      def open_stream(&block)
        if m = /^jar:file:\/\/(.*)!\/(.*)/.match(@location)
          Zip::ZipFile.new(m[1]).get_input_stream(m[2], &block)
        elsif m = /^file:\/\/(.*)/.match(@location)
          File.open(m[1], "rb", &block)
        else
          raise "Dont know how to open resource #{@location}"
        end
      end
    end
  end
end
