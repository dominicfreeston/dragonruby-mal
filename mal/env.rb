module Mal
  class Env
    attr_accessor :data
    
    def initialize outer=nil, binds=[], exprs=[]
      @outer = outer
      @data = {}
      binds.each_with_index do |e, i|
        if e == :&
          @data[binds[i+1]] = List.new exprs.drop(i)
          break
        end
        @data[e] = exprs[i]
      end
    end

    def set k, v
      @data[k] = v
    end

    def find k
      return self if @data.key? k
      return @outer.find(k) if @outer
      return nil
    end

    def get k
      env = find k
      raise MalException.new "'" + k.to_s + "' not found" if not env
      env.data[k]
    end
  end
end
