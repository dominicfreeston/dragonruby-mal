module Mal
  class Repl
    def READ i
      i
    end

    def EVAL i
      i
    end

    def PRINT i
      i
    end

    def REP i
      (PRINT (EVAL (READ i)))
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
  end
end

