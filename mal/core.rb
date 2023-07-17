module Mal
  module Namespace
    class Core
      attr_accessor :ns
      
      def initialize
        @ns = {}
        
        @ns[:+] = lambda { |*args| args.reduce(:+) }
        @ns[:-] = lambda { |*args| args.reduce(:-) }
        @ns[:*] = lambda { |*args| args.reduce(:*) }
        @ns[:/] = lambda { |*args| args.reduce(:/) }
        
        @ns[:list] = lambda do |*args|
          List.new args
        end

        @ns[:list?] = lambda do |l|
          l.is_a? List
        end

        @ns[:empty?] = lambda do |l|
          l.nil? or l.empty?
        end

        @ns[:count] = lambda do |l|
          l.nil? ? 0 : l.length
        end

        @ns[:nth] = lambda do |l, i|
          raise "Index (" + i + ") out of range" if i < 0 || i >= l.length
          l[i]
        end

        @ns[:first] = lambda do |l|
          if (not l) || l.empty?
            nil
          else
            l[0]
          end
        end

        @ns[:rest] = lambda do |l|
          List.new(l&.drop(1) || [])
        end

        @ns[:cons] = lambda do |c, l|
          List.new [c] + l
        end

        @ns[:concat] = lambda do |*ls|
          List.new (ls && ls.reduce(:+)) || []
        end

        @ns[:vec] = lambda do |l|
          if l.is_a? Vector then l else Vector.new l end
        end
        
        @ns["=".intern] = lambda do |a, b|
          # keywords should only be equal to keywords
          if a.is_a?(Keyword) || b.is_a?(Keyword)
            return false unless a.class == b.class
          end
          
          a == b
        end

        @ns[:<] = lambda do |a, b|
          a < b
        end

        @ns[:<=] = lambda do |a, b|
          a <= b
        end

        @ns[:>] = lambda do |a, b|
          a > b
        end

        @ns[:>=] = lambda do |a, b|
          a >= b
        end

        @ns["pr-str".intern] = lambda do |*args|
          args.map do |a|
            Mal.pr_str(a, true)
          end.join(" ")
        end

        @ns[:str] = lambda do |*args|
          args.map do |a|
            Mal.pr_str(a, false)
          end.join("")
        end

        @ns[:prn] = lambda do |*args|
          print (args.map do |a|
                   Mal.pr_str(a, true)
                 end.join(" "))
          nil
        end

        @ns[:println] = lambda do |*args|
          print (args.map do |a|
                   Mal.pr_str(a, false)
                 end.join(" ")) + "\n"
          nil
        end

        @ns["read-string".intern] = lambda do |s|
          Mal.read_str(s)
        end

        @ns[:slurp] = lambda do |f|
          $gtk.read_file f
        end

        @ns[:atom] = lambda do |v|
          Atom.new v
        end

        @ns[:atom?] = lambda do |a|
          a.is_a? Atom
        end

        @ns[:deref] = lambda do |a|
          raise "attempting to deref" unless a.is_a? Atom
          a.val
        end

        @ns[:reset!] = lambda do |a, v|
          a.val = v
          v
        end

        @ns[:swap!] = lambda do |a, f, *rest|
          f = f.is_a?(Function) ? f.fn : f
          a.val = f[a.val, *rest]
          a.val
        end

        @ns[:throw] = lambda do |v|
          raise MalException.new v
        end

        @ns[:map] = lambda do |f, l|
          f = f.fn if f.is_a? Function
          List.new l.map(&f)
        end

        @ns[:nil?] = lambda do |v|
          v.nil?
        end

        @ns[:true?] = lambda do |v|
          true == v
        end

        @ns[:false?] = lambda do |v|
          false == v
        end

        @ns[:symbol?] = lambda do |v|
          v.is_a? Symbol
        end

        @ns[:keyword?] = lambda do |k|
          k.is_a? Keyword
        end

        @ns[:sequential?] = lambda do |s|
          s.is_a? Array
        end

        @ns[:vector?] = lambda do |s|
          s.is_a? Vector
        end

        @ns[:map?] = lambda do |m|
          m.is_a? Map
        end

        @ns[:symbol] = lambda do |s|
          s.intern
        end

        @ns[:keyword] = lambda do |s|
          if s.is_a? Keyword
            s
          else
            Keyword.new ":" + s
          end
        end

        @ns[:vector] = lambda do |*args|
          Vector.new args
        end

        @ns["hash-map".intern] = lambda do |*args|
          Map[args.each_slice(2).to_a]
        end

        @ns[:assoc] = lambda do |m, *args|
          m.merge Map[args.each_slice(2).to_a]
        end

        @ns[:dissoc] = lambda do |m, *args|
          m = m.dup
          args.each { |k| m.delete k }
          m
        end

        @ns[:get] = lambda do |m, k|
          (m || {})[k]
        end

        @ns[:contains?] = lambda do |m, k|
          (m || {}).has_key? k
        end

        @ns[:keys] = lambda do |m|
          List.new m.keys
        end

        @ns[:vals] = lambda do |m|
          List.new m.values
        end

        @ns[:apply] = lambda do |f, *args|
          f = f.fn if f.is_a? Function
          f[*args[0...-1], *args.last]
        end
                                           
      end
    end

    @core = Core.new
    
    def self.core
      @core.ns
    end
  end
end
