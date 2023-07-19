module Mal

  # Can't add instance vars to core types in mruby
  # so need a workaround to store meta information
  # note that meta is currently not carried over on dup
  @@meta = {}
  
  def self.meta
    @@meta
  end

  module WithMeta
    def meta
      Mal.meta[self.object_id]
    end

    def meta= m
      Mal.meta[self.object_id] = m
    end
  end
  
  class List < Array
    include WithMeta
  end

  class Vector < Array
    include WithMeta
  end

  class Map < Hash
    include WithMeta
  end

  class Keyword < String
    def initialize s
      super s
      self.freeze
    end
  end

  class Function
    include WithMeta
    
    attr_accessor :ast, :params, :env, :fn, :is_macro

    def initialize is_macro=false
      @is_macro = is_macro
    end
  end


  class Atom
    include WithMeta
    attr_accessor :val

    def initialize v
      @val = v
    end
  end

  class ::Proc
    include WithMeta
  end

  class MalException < Exception
    attr_accessor :val

    def initialize v
      @val = v
    end

    def to_s
      @val.to_s
    end
  end
end
