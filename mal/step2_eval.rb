module Mal
  class Repl
    def initialize
        @repl_env = {}
        @repl_env[:+] = Proc.new { |*args| args.reduce(:+) }
        @repl_env[:-] = Proc.new { |*args| args.reduce(:-) }
        @repl_env[:*] = Proc.new { |*args| args.reduce(:*) }
        @repl_env[:/] = Proc.new { |*args| args.reduce(:/) }
    end
    
    def debug_log i
      # print i.to_s + "\n"
    end

    def eval_ast ast, env
      case ast
      when Symbol
        raise "'" + ast.to_s + "' not found" if not env.key? ast
        env[ast]
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

