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

        RE = lambda {|str| EVAL(READ(str), @repl_env) }
        RE["(def! not (fn* (a) (if a false true)))"]
        RE["(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"]
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

    def READ i
      debug_log "READ " + i.to_s
      Mal.read_str(i)
    end

    def EVAL ast, env
      while true
        if not ast.is_a? List
          return eval_ast(ast, env)
        end
        
        if ast.empty?
          return ast
        end

        sym = ast[0].sym if ast[0].is_a? MalSymbol
        
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
        "* Mal Error: #{e} *"
      end
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
  
  loop do
    print "input> "
    line = gets
    break unless line
    print repl.REP(line)
    print "\n"
  end
end

