def debug_log i
  # print i.to_s + "\n"
end

def READ i
  debug_log "READ " + i.to_s
  Mal.read_str(i)
end

def EVAL i
  i
end

def PRINT i
  debug_log "PRINT " + i.to_s
  (Mal.pr_str i)
end

def REP i
  begin
    (PRINT (EVAL (READ i)))
  rescue Exception => e
    "* Error: #{e} *"
  end
end

def run_repl
  loop do
    print "input> "
    line = gets
    break unless line
    print REP(line)
    print "\n"
  end
end

