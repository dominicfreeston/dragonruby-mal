module Mal

  class List < Array
  end

  class Vector < Array
  end

  class Map < Hash
  end

  class Keyword < String
    def initialize s
      super s
      self.freeze
    end
  end

  class Function
    attr_accessor :ast, :params, :env, :fn
  end


end
