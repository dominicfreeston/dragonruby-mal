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

def run_repl
  loop do
    print "input> "
    line = gets
    break unless line
    print REP(line)
  end
end

