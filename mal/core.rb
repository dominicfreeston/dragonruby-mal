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
                                           
      end
    end

    @core = Core.new
    
    def self.core
      @core.ns
    end
  end
end
