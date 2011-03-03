module Charm
  module Bytecode

    module Sexp
      def sexp
        ary = [self.class.name.downcase.split('::').last.intern]
        ary.push *instance_variables.map { |iname|
          val = instance_variable_get(iname) 
          if val.kind_of?(Array)
            val = val.map { |v| if v.respond_to?(:sexp) then v.sexp else v end }
          elsif val.respond_to?(:sexp)
            val = val.sexp
          end
          [iname.to_s[1..-1].intern, val]
        }
        ary
      end
    end

    class Loader
      include Sexp
    end

  end
end
