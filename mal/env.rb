module Mal
  class Env
    attr_accessor :data
    
    def initialize outer=nil, binds=[], exprs=[]
      @outer = outer
      @data = {}
      binds.each_with_index do |e, i|
        if e.sym == :&
          @data[binds[i+1].sym] = List.new exprs.drop(i)
          break
        end     
        @data[e.sym] = exprs[i]
      end
    end

    def set k, v
      @data[k.sym] = v
    end

    def find k
      return self if @data.key? k.sym
      return @outer.find(k) if @outer
      return nil
    end

    def get k
      env = find k
      raise MalException.new "symbol '" + k.sym.to_s + "' not found" if not env
      env.data[k.sym]
    end
  end
end
