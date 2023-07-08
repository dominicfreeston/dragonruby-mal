module Mal
  class Repl
    def initialize
        @repl_env = Env.new nil
        
        @repl_env.set(:+, lambda { |*args| args.reduce(:+) })
        @repl_env.set(:-, lambda { |*args| args.reduce(:-) })
        @repl_env.set(:*, lambda { |*args| args.reduce(:*) })
        @repl_env.set(:/, lambda { |*args| args.reduce(:/) })
    end
    
    def debug_log i
      # print i.to_s + "\n"
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
      else
        ast
      end
    end

    def READ i
      debug_log "READ " + i.to_s
      Mal.read_str(i)
    end

    def EVAL ast, env
      if not ast.is_a? List
        return eval_ast(ast, env)
      end
      
      if ast.empty?
        return ast
      end
      
      if ast[0] == :def!
        return env.set(ast[1], EVAL(ast[2], env))
      end

      if ast[0] == :"let*"
        let_env = Env.new env
        bindings = ast[1]
        bindings.each_slice(2) do |(k, v)|
          let_env.set(k, EVAL(v, let_env))                   
        end
        return EVAL(ast[2], let_env)
      end

      # apply list
      el = eval_ast(ast, env)
      f = el[0]
      return f[*el.drop(1)]
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
  loop do
    print "input> "
    line = gets
    break unless line
    print repl.REP(line)
    print "\n"
  end
end
