module Mal
  class Env
    attr_accessor :data
    
    def initialize outer
      @outer = outer
      @data = {}
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
      raise "'" + k.to_s + "' not found" if not env
      env.data[k]
    end
  end
end
