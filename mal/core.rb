module Mal
  module Namespace
    @@ns = {
      :+ => lambda { |*args| args.reduce(:+) },
      :- => lambda { |*args| args.reduce(:-) },
      :* => lambda { |*args| args.reduce(:*) },
      :/ => lambda { |*args| args.reduce(:/) },
      
      :list => lambda do |*args|
        List.new args
      end,

      :list? => lambda do |l|
        l.is_a? List
      end,

      :empty? => lambda do |l|
        l.nil? or l.empty?
      end,

      :count => lambda do |l|
        l.nil? ? 0 : l.length
      end,
      
      "=".intern => lambda do |a, b|
        # keywords should only be equal to keywords
        if a.is_a?(Keyword) || b.is_a?(Keyword)
          return false unless a.class == b.class
        end
        
        a == b
      end,

      :< => lambda do |a, b|
        a < b
      end,

      :<= => lambda do |a, b|
        a <= b
      end,

      :> => lambda do |a, b|
        a > b
      end,

      :>= => lambda do |a, b|
        a >= b
      end,

      "pr-str".intern => lambda do |*args|
        args.map do |a|
          Mal.pr_str(a, true)
        end.join(" ")
      end,

      :str => lambda do |*args|
        args.map do |a|
          Mal.pr_str(a, false)
        end.join("")
      end,

      :prn => lambda do |*args|
        print (args.map do |a|
          Mal.pr_str(a, true)
        end.join(" "))
        nil
      end,

      :println => lambda do |*args|
        print (args.map do |a|
          Mal.pr_str(a, false)
        end.join(" "))
        nil
      end,
    }

    def self.core
      @@ns
    end
  end
end
