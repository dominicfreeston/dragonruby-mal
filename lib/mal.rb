module Mal
  WHITESPACE = {" " => :SPACE,
                "\n" => :NEWLINE,
                "\r" => :CARRIAGE_RETURN,
                "\t" => :TAB,
                "," => :COMMA
               }
  
  SPECIALS = {"[" => :OPEN_SQUARE,
              "]" => :CLOSE_SQUARE,
              "{" => :OPEN_BRACE,
              "}" => :CLOSE_BRACE,
              "(" => :OPEN_PAREN,
              ")" => :CLOSE_PAREN,
              "'" => :QUOTE,
              "`" => :BACKTICK,
              "~" => :TILDE,
              "^" => :CARET,
              "@" => :AT
             }

  class Reader
    def initialize tokens
      @tokens = tokens
      @position = 0
    end

    def next
      @position += 1
      @tokens[@position - 1]
    end

    def peek
      @tokens[@position]
    end
  end

  #-----
  
  def self.read_str s
    tokens = (tokenize s)
    return nil if tokens.size == 0
    (read_form (Reader.new tokens)) 
  end
  
  def self.tokenize s
    tokens = []    
    pos = 0

    while pos < s.size
      c = s[pos]
      
      if WHITESPACE[c]
        pos += 1
      elsif (c == "~") &&
            (pos + 1 < s.size) &&
            (s[pos + 1] == "@")
        tokens << :TAT
        pos += 2
      elsif sp = SPECIALS[c]
        tokens << sp
        pos += 1
      elsif c == "\""
        start = pos

        # advance until you find a " not preceded by a \
        # keeping in mind \\ doesn't count
        c = 0
        while pos < s.length
          pos += 1

          if s[pos] == "\"" && (c % 2) == 0
            break
          elsif s[pos] == "\\"
            c = c + 1
          else
            c = 0
          end
        end
        
        pos += 1

        tokens << s[start...pos]
      elsif c == ";"
        start = pos
        pos += 1 while (pos < s.size) &&
                       (s[pos] != "\n")
        # tokenizing it just means we have to deal with it later?
        # and somehow differentiate between it and nil
        # tokens << s[start...pos]
      else
        start = pos
        pos += 1 while (pos < s.size) &&
                       !(SPECIALS[s[pos]]) &&
                       !(WHITESPACE[s[pos]]) &&
                       !(";" == s[pos])
        tokens << s[start...pos]
      end
      
    end

    return tokens
  end

  def self.read_form reader
    case reader.peek
    when :QUOTE
      reader.next
      List.new [MalSymbol.new(:quote), (read_form reader)]
    when :BACKTICK
      reader.next
      List.new [MalSymbol.new(:quasiquote), (read_form reader)]
    when :TILDE
      reader.next
      List.new [MalSymbol.new(:unquote), (read_form reader)]
    when :TAT
      reader.next
      List.new [MalSymbol.new(:"splice-unquote"), (read_form reader)]
    when :CARET
      reader.next
      meta = read_form reader
      List.new [MalSymbol.new(:"with-meta"), (read_form reader), meta]
    when :AT
      reader.next
      List.new [MalSymbol.new(:deref), (read_form reader)]
    when :OPEN_PAREN
      read_list reader, List, :CLOSE_PAREN
    when :OPEN_SQUARE
      read_list reader, Vector, :CLOSE_SQUARE
    when :OPEN_BRACE
      Map[(read_list reader, List, :CLOSE_BRACE).each_slice(2).to_a]
    else
      read_atom reader
    end
  end

  def self.read_list reader, type=List, close=:CLOSE_PAREN
    ast = type.new

    reader.next
    
    while (token = reader.peek) != close
      if not token
        raise MalException.new "expected '" + close.to_s + "', got EOF"
      end
      ast << read_form(reader)
    end
    
    reader.next
    
    ast
  end

  def self.read_atom reader
    a = reader.next

    return nil if a == "nil"
    return true if a == "true"
    return false if a == "false"
    
    return a.delete_prefix(":").intern if a.start_with? ":"
    return parse_str a if a.start_with? "\""

    
    i = begin Integer(a) rescue nil end
    return i if i
    
    return MalSymbol.new(a.intern)
  end

  def self.parse_str s
    ok = (s.end_with? "\"") && (s.length > 1)
    s = s[1...-1]
    
    suffix = ""
    s.reverse.each_char do |c|
      if c == "\\"
       suffix += c
      else
        break
      end
    end

    ok = ok && suffix.length.even?

    raise MalException.new "expected '\"', got EOF" unless ok

    r = ""
    leading = false
    s.each_char do |c|
      if c == "\\"
        r += "\\" if leading
      elsif !leading
        r += c
        leading = true
      elsif c == "n"
        r += "\n"
      elsif c == "t"
        r += "\t"
      elsif c == "\""
        r += "\""
      end
      leading = !leading
    end
    r
  end
end


module Mal
  def self.pr_str f, print_readably=true
    r = print_readably
    case f
    when MalException
      pr_str f.val
    when List
      "(" + f.map { |f| pr_str f, r }.join(" ")  + ")"
    when Vector
      "[" + f.map { |f| pr_str f, r }.join(" ")  + "]"
    when Map
      ret = []
      f.each{ |k,v| ret.push (pr_str k, r), (pr_str v, r) }
      "{" + ret.join(" ") + "}"
    when MalSymbol
      f.sym.to_s
    when Keyword
      ":" + f.to_s
    when String
      if r
        f.inspect
      else
        f
      end
    when Atom
      "(atom " + self.pr_str(f.val, r) + ")"
    when Function
      "#function"
    when Proc
      "#function"
    when nil
      "nil"
    else
      f.to_s
    end
  end
end


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

  Keyword = Symbol

  class MalSymbol
    def sym
      @sym
    end
    
    def initialize sym
      @sym = sym
    end

    def == other
      other.is_a?(MalSymbol) && self.sym == other.sym
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
          v.is_a? MalSymbol
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
          MalSymbol.new s.intern
        end

        @ns[:keyword] = lambda do |s|
          if s.is_a? Keyword
            s
          else
            s.intern
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

        @ns[:readline] = lambda do |prompt|
          print prompt
          r = gets
          # chop off trailing \n
          r && r[0...-1]
        end

        @ns["time-ms".intern] = lambda do
          (Time.now.to_f * 1000).to_i
        end
        
        @ns[:meta] = lambda do |v|
          v.meta
        end
        
        @ns[:fn?] = lambda do |f|
          f.is_a?(Proc) || f.is_a?(Function) && !f.is_macro
        end

        @ns[:macro?] = lambda do |f|
          f.is_a?(Function) && f.is_macro
        end
        
        @ns[:string?] = lambda do |s|
          s.is_a?(String) && !s.is_a?(Keyword)
        end
        
        @ns[:number?] = lambda do |n|
          n.is_a? Numeric
        end
        
        @ns[:seq] = lambda do |s|
          return nil if s.nil? || s.size == 0
          
          case s             
          when List
            s
          when Vector
            List.new s
          when String
            List.new s.split("")
          end
        end
        
        @ns[:conj] = lambda do |s, *args|
          s = s.clone
          case s
          when List
            args.each { |v| s.unshift v }
          when Vector
            args.each { |v| s.push v }
          end
          s
        end
      
        @ns["with-meta".intern] = lambda do |v, m|
          v = v.clone
          v.meta = m
          v
        end
      end
    end

    @core = Core.new
    
    def self.core
      @core.ns
    end
  end
end


module Mal
  class Repl
    def initialize
        @repl_env = Env.new
        Namespace.core.each do |k, v|
          @repl_env.set(MalSymbol.new(k), v)
        end

        @repl_env.set(
          MalSymbol.new(:"*ARGV*"),
          List.new([])
        )
        
        @repl_env.set(
          MalSymbol.new(:eval),
          lambda do |ast| 
            EVAL ast, @repl_env
          end
        )

        @repl_env.set(
          MalSymbol.new(:"print-env"),
          lambda do
            print(@repl_env.data.keys.map do |s|
                    s.to_s
                  end.to_s + "\n")
          end
        )
        
        RE "(def! *host-language* \"DragonRuby\")"
        RE "(def! not (fn* (a) (if a false true)))"
        RE "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"
        RE "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"
    end

    def set_argv argv
      @repl_env.set(
        MalSymbol.new(:"*ARGV*"),
        List.new(argv)
      )
    end
    
    def debug_log i
      # print i.to_s + "\n"
    end

    def process_quasiquote ast
      res = List.new []
      ast.reverse_each do |e|
        if e.is_a?(List) &&
           (s = e[0]).is_a?(MalSymbol) &&
           s.sym == :"splice-unquote"
          res = List.new [MalSymbol.new(:concat), e[1], res]
        else
          res = List.new [MalSymbol.new(:cons), quasiquote(e), res]
        end
      end
      res
    end

    def quasiquote ast
      case ast
      when List
        if (s = ast[0]).is_a?(MalSymbol) && s.sym == :unquote
          ast[1]
        else
          process_quasiquote(ast)
        end
      when Vector
        List.new [MalSymbol.new(:vec), process_quasiquote(ast)]
      when Map
        List.new [MalSymbol.new(:quote), ast]
      when MalSymbol
        List.new [MalSymbol.new(:quote), ast]
      else
        ast
      end
    end

    def eval_ast ast, env
      case ast
      when MalSymbol
        env.get ast
      when List
        List.new ast.map { |a| (EVAL a, env) }
      when Vector
        Vector.new ast.map { |a| (EVAL a, env) }
      when Map
        m = Map.new
        ast.each_key { |k| m[k] = EVAL(ast[k], env) }
        m
      when Array
        raise "unexpected Array in ast (use subclass)"
      else
        ast
      end
    end

    def is_macro_call ast, env
      ast.is_a?(List) &&
        (a0 = ast[0]).is_a?(MalSymbol) &&
        (e = env.find(a0)) &&
        (f = e.get(a0)).is_a?(Function) &&
        f.is_macro
    end

    def macroexpand ast, env
      while is_macro_call(ast, env)
        f = env.get(ast[0])
        ast = f.fn[*ast.drop(1)]
      end
      ast
    end

    def READ i
      debug_log "READ " + i.to_s
      Mal.read_str(i)
    end

    def EVAL ast, env
      while true        
        ast = macroexpand(ast, env)
         
        if not ast.is_a? List
          return eval_ast(ast, env)
        end
        
        if ast.empty?
          return ast
        end

        sym = ast[0].sym if ast[0].is_a? MalSymbol
        
        if sym == :macroexpand
          return macroexpand(ast[1], env)
        end

        if sym == :quote
          return ast[1]
        end

        if sym == :quasiquote
          ast = quasiquote(ast[1])
          next
        end

        if sym == :quasiquoteexpand
          return ast = quasiquote(ast[1])
        end
        
        if sym == :def!
          return env.set(ast[1], EVAL(ast[2], env))
        end

        if sym == :defmacro!
          f = EVAL(ast[2], env).dup
          f.is_macro = true
          return env.set(ast[1], f)
        end

        if sym == :"let*"
          let_env = Env.new env
          bindings = ast[1]
          bindings.each_slice(2) do |(k, v)|
            let_env.set(k, EVAL(v, let_env))                   
          end
          env = let_env
          ast = ast[2]
          next
        end

        if sym == :do
          eval_ast(List.new(ast[1..-2]), env)
          ast = ast.last
          next
        end

        if sym == :if
          if EVAL(ast[1], env)
            ast = ast[2]
          else
            return nil if ast[3] == 0
            ast = ast[3]
          end
          next
        end

        if sym == :"try*"
          begin
            
            res = EVAL(ast[1], env)
            return res
            
          rescue Exception => e
            
            ctch = ast[2]
            if ctch &&
               (s = ctch[0]).is_a?(MalSymbol) &&
               s.sym == :"catch*"
              
              return EVAL(ctch[2], Env.new(env, [ctch[1]], [e]))
            else
              raise e
            end
            
          end
        end

        if sym == :"fn*"
          binds = ast[1]
          f = Function.new
          f.ast = ast[2]
          f.params = ast[1]
          f.env = env
          
          f.fn = lambda do |*args|
            fn_env = Env.new env, binds, args
            EVAL(ast[2], fn_env)
          end          
          return f
        end

        # apply list
        el = eval_ast(ast, env)
        f = el[0]
        if f.class == Function
            ast = f.ast
            env = Env.new f.env, f.params, el.drop(1)
        else
            return f[*el.drop(1)]
        end
      end
    end

    def PRINT ast
      debug_log "PRINT " + ast.to_s
      (Mal.pr_str ast)
    end
  
    def REP i 
      begin
        (PRINT (EVAL (READ i), @repl_env))
      rescue Exception => e
        if e.is_a? MalException
          "* Mal Error: #{Mal.pr_str(e)} *"
        else
          "* Error: #{e}"
        end
      end
    end

    def RE str
      EVAL(READ(str), @repl_env)
    end
    
  end
end

def run_repl
  repl = Mal::Repl.new
  
  if arg_string = $gtk.cli_arguments[:run]
    # maybe improve this to allow quoting
    args = arg_string.split(" ")
    repl.set_argv(args.drop 1)
    cmd = "(load-file \"" + args[0] + "\")"
    repl.REP(cmd)
    return
  end

  repl.RE "(println (str \"Mal [\" *host-language* \"]\"))"
  
  loop do
    print "input> "
    line = gets
    break unless line
    print repl.REP(line)
    print "\n"
  end
end

