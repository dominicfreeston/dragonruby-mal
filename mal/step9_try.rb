module Mal
  class Repl
    def initialize
        @repl_env = Env.new
        Namespace.core.each do |k, v|
          @repl_env.set(k, v)
        end

        @repl_env.set(
          :"*ARGV*",
          List.new([])
        )
        
        @repl_env.set(
          :eval,
          lambda do |ast| 
            EVAL ast, @repl_env
          end
        )

        @repl_env.set(
          :"print-env",
          lambda do
            print(@repl_env.data.keys.map do |s|
                    s.to_s
                  end.to_s + "\n")
          end
        )

        RE = lambda {|str| EVAL(READ(str), @repl_env) }
        RE["(def! not (fn* (a) (if a false true)))"]
        RE["(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"]
        RE["(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"]
    end

    def set_argv argv
      @repl_env.set(
        :"*ARGV*",
        List.new(argv)
      )
    end
    
    def debug_log i
      # print i.to_s + "\n"
    end

    def process_quasiquote ast
      res = List.new []
      ast.reverse_each do |e|
        if e.is_a?(List) && e[0] == :"splice-unquote"
          res = List.new [:concat, e[1], res]
        else
          res = List.new [:cons, quasiquote(e), res]
        end
      end
      res
    end
    
    def quasiquote ast
      case ast
      when List
        if ast[0] == :unquote
          ast[1]
        else
          process_quasiquote(ast)
        end
      when Vector
        List.new [:vec, process_quasiquote(ast)]
      when Map
        List.new [:quote, ast]
      when Symbol
        List.new [:quote, ast]
      else
        ast
      end
    end
    
    def eval_ast ast, env
      case ast
      when Symbol
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
        (a0 = ast[0]).is_a?(Symbol) &&
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

        if ast[0] == :macroexpand
          return macroexpand(ast[1], env)
        end

        if ast[0] == :quote
          return ast[1]
        end

        if ast[0] == :quasiquote
          ast = quasiquote(ast[1])
          next
        end

        if ast[0] == :quasiquoteexpand
          return ast = quasiquote(ast[1])
        end
        
        if ast[0] == :def!
          return env.set(ast[1], EVAL(ast[2], env))
        end

        if ast[0] == :defmacro!
          f = EVAL(ast[2], env)
          f.is_macro = true
          return env.set(ast[1], f)
        end

        if ast[0] == :"let*"
          let_env = Env.new env
          bindings = ast[1]
          bindings.each_slice(2) do |(k, v)|
            let_env.set(k, EVAL(v, let_env))                   
          end
          env = let_env
          ast = ast[2]
          next
        end

        if ast[0] == :do
          eval_ast(List.new(ast[1..-2]), env)
          ast = ast.last
          next
        end

        if ast[0] == :if
          if EVAL(ast[1], env)
            ast = ast[2]
          else
            return nil if ast[3] == 0
            ast = ast[3]
          end
          next
        end

        if ast[0] == :"try*"
          begin
            
            res = EVAL(ast[1], env)
            return res
            
          rescue Exception => e
            
            ctch = ast[2]
            if ctch && ctch[0] == :"catch*"
              return EVAL(ctch[2], Env.new(env, [ctch[1]], [e]))
            else
              raise e
            end
            
          end
        end

        if ast[0] == :"fn*"
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

